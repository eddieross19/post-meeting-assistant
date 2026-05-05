# Post Meeting Assistant - Agentforce POC

An Agentforce employee agent that helps sales wholesalers with pre-meeting preparation and post-meeting follow-up automation. Built on the Salesforce Agentforce platform using the ReAct planner.

## What It Does

The Post Meeting Assistant handles two core workflows:

### Pre-Meeting Preparation
- **Contact Summaries** — Generates rich-text summaries of contacts including their account info, open opportunities, cases, last activity date, and key metrics with clickable Salesforce record links
- **Meeting Agenda Preparation** — Creates structured agendas for sales meetings and shares them via Slack Canvas
- **Participant Insights** — Provides background on meeting participants using personalization data
- **Product Recommendations** — Surfaces tailored product recommendations based on client data
- **Sales Data Analysis** — Analyzes sales trends for life and annuity products using Data Cloud

### Post-Meeting Follow-Up
- **Post Meeting Summary** — Summarizes key discussion points, decisions made, and actionable next steps
- **Actionable Next Steps** — Creates follow-up tasks and communicates them via Slack channels
- **Task, Event & Opportunity Creation** — Automatically creates CRM records (tasks, events, opportunities) from meeting notes via flow automation

## Architecture

```
Post_Meeting_Assistant (GenAiPlannerBundle - ReAct)
├── Topics (GenAiPlugins)
│   ├── Meeting Prep — contact summary via prompt template
│   ├── Post Meeting Summary — discussion recap & action items
│   ├── Meeting Agenda Preparation — Slack Canvas creation
│   ├── Participant Insights Summary — personalization context
│   ├── Product Recommendation Brief — knowledge-based recommendations
│   ├── Sales Data Analysis — Data Cloud integration
│   └── Actionable Next Steps — Slack channel notifications
├── Actions (GenAiFunctions)
│   ├── Meeting_Prep — prompt template invocation
│   └── ESK_Flow_for_Agent — flow for creating CRM records
├── Prompt Templates
│   ├── Meeting_Prep — contact summary with rich text & hyperlinks
│   └── Post_Meeting_Clean_Up_Prompt
├── Flows
│   ├── ESK_Flow_for_Agent — creates events, tasks, opportunities
│   ├── ESK_Post_Meeting_Wrap_Up
│   ├── ESK_My_MEETINGS_summaries
│   ├── ESK_Flow_to_get_Contact_v2
│   ├── esk_flow_for_meeting_prep_summary
│   └── esk_flow_that_updates_events_with_contact_summary_powered_by_prompts
├── Apex Classes
│   └── CRMIntegrationService
└── Custom Objects
    └── CMDT__c (with Opportunity_Record_Type__c field)
```

## Prerequisites

- Salesforce org with **Agentforce** enabled
- **Einstein Generative AI** enabled
- **Data Cloud** connected (for Sales Data Analysis topic)
- **Slack integration** configured (for agenda sharing and follow-up notifications)
- Salesforce CLI (`sf`) v2.x installed

## Deployment

### 1. Authenticate to your target org

```bash
sf org login web --alias my-org
```

### 2. Deploy the metadata

This is a standard Salesforce DX (SFDX) project. The `sfdx-project.json` file at the root tells the Salesforce CLI which directories contain deployable metadata (in this case, everything under `force-app/`). The deploy command reads that config and pushes all components to your org in the correct order:

```bash
sf project deploy start --target-org my-org
```

To preview what will be deployed without making changes:

```bash
sf project deploy preview --target-org my-org
```

If you only want to deploy specific components (e.g., just the flows):

```bash
sf project deploy start --target-org my-org --source-dir force-app/main/default/flows
```

### 3. Post-Deployment Setup

1. **Activate the Agent** — Navigate to Setup > Agents > Post Meeting Assistant and activate it
2. **Configure Slack** — Ensure your Slack Connected App is set up and the Slack actions are authorized
3. **Data Cloud** — Verify Data Cloud is connected if you want Sales Data Analysis to work
4. **Knowledge Base** — Populate Knowledge articles for the "Answer Questions with Knowledge" action
5. **Custom Object** — Configure `CMDT__c` with the appropriate Opportunity Record Type values for your org
6. **Test** — Open the Agent in the Agentforce testing panel and try:
   - "Prepare me to meet John Smith"
   - "Summarize my last meeting and create follow-up tasks"

## Integrations

| Integration | Used By | Purpose |
|-------------|---------|---------|
| Slack | Meeting Agenda Preparation, Actionable Next Steps | Canvas creation, channel messaging |
| Data Cloud | Sales Data Analysis | Sales trend data retrieval |
| Einstein Knowledge | Multiple topics | Policy/product Q&A |
| Personalization | Participant Insights | Contact context enrichment |

## Project Structure

```
force-app/main/default/
├── bots/                    # Bot channel configuration
├── classes/                 # Apex classes
├── flows/                   # Automation flows
├── genAiFunctions/          # Agent actions
├── genAiPlannerBundles/     # Agent definition
├── genAiPlugins/            # Agent topics
├── genAiPromptTemplates/    # Prompt templates
└── objects/                 # Custom objects
```

## Notes

- The Meeting Prep prompt template generates HTML-formatted summaries with clickable record links — this is optimized for the Agentforce messaging surface
- Some topics reference standard Agentforce actions (IdentifyRecordByName, QueryRecords, SummarizeRecord) that are available out-of-the-box in orgs with Agentforce enabled
- The `CMDT__c` custom object stores configuration for Opportunity Record Type mappings used by the post-meeting flows
