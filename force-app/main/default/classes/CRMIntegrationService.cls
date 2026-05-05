public without sharing class CRMIntegrationService {

    public class FlowInput {
        @InvocableVariable(label='Raw JSON String' required=true)
        public String rawJson;
        @InvocableVariable(label='Account ID' required=true)
        public Id accountId;
    }

    public class FlowOutput {
        @InvocableVariable public List<String> eventNames = new List<String>();
        @InvocableVariable public List<String> taskNames = new List<String>();
        @InvocableVariable public List<String> oppNames = new List<String>();
        @InvocableVariable public String errorMessage;
    }

    public class MeetingData {
        public EventData event;
        public List<TaskData> tasks;
        public List<OpportunityData> opportunities; 
    }
    
    public class EventData { public String event_name; public DateTime event_date; public String event_attendee; }
    public class TaskData { public String task_name; public Date task_due_date; public String task_priority; public String assigned_to_user_name; }
    public class OpportunityData { public String opportunity_name; public Date opportunity_close_date; public Decimal opportunity_amount; }

    @InvocableMethod(label='Process Meeting JSON - Final Bulkified')
    public static List<FlowOutput> processJsonInput(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        
        for (FlowInput input : inputs) {
            FlowOutput res = new FlowOutput();
            System.Savepoint sp = Database.setSavepoint();
            
            try {
                String cleanJson = sanitizeJson(input.rawJson);
                MeetingData data = (MeetingData)JSON.deserialize(cleanJson, MeetingData.class);

                // --- PRE-FETCH USERS (To avoid Query-in-Loop error) ---
                Map<String, Id> userMap = new Map<String, Id>();
                if (data.tasks != null) {
                    Set<String> userNames = new Set<String>();
                    for (TaskData td : data.tasks) { if (String.isNotBlank(td.assigned_to_user_name)) userNames.add(td.assigned_to_user_name); }
                    if (!userNames.isEmpty()) {
                        for (User u : [SELECT Id, Name FROM User WHERE Name IN :userNames AND IsActive = true]) {
                            userMap.put(u.Name, u.Id);
                        }
                    }
                }

                // 1. Create Event
                if (data.event != null) {
                    insert new Event(Subject=data.event.event_name, StartDateTime=data.event.event_date, EndDateTime=data.event.event_date.addHours(1), WhatId=input.accountId);
                    res.eventNames.add(data.event.event_name);
                }

                // 2. Create Tasks with Assignment
                if (data.tasks != null) {
                    List<Task> tList = new List<Task>();
                    for (TaskData td : data.tasks) {
                        Task t = new Task(Subject=td.task_name, ActivityDate=td.task_due_date, Priority=td.task_priority, WhatId=input.accountId, Status='Not Started');
                        if (userMap.containsKey(td.assigned_to_user_name)) {
                            t.OwnerId = userMap.get(td.assigned_to_user_name);
                        }
                        tList.add(t);
                    }
                    insert tList;
                    for(Task t : tList) res.taskNames.add(t.Subject);
                }

                // 3. Create Opportunities
                if (data.opportunities != null) {
                    List<Opportunity> oList = new List<Opportunity>();
                    for (OpportunityData od : data.opportunities) {
                        oList.add(new Opportunity(Name=od.opportunity_name, CloseDate=od.opportunity_close_date, Amount=od.opportunity_amount, AccountId=input.accountId, StageName='Prospecting'));
                    }
                    insert oList;
                    for(Opportunity o : oList) res.oppNames.add(o.Name);
                }

            } catch (Exception e) {
                Database.rollback(sp);
                res.errorMessage = 'ERROR: ' + e.getMessage();
            }
            outputs.add(res);
        }
        return outputs;
    }

    private static String sanitizeJson(String input) {
        String result = input.trim();
        if (result.startsWith('```json')) result = result.substringAfter('```json');
        if (result.endsWith('```')) result = result.substringBeforeLast('```');
        return result.trim();
    }
}