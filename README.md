# TalentTrack – Recruitment Management System

TalentTrack is a Salesforce-based Recruitment Management System designed to simplify and automate the recruitment process. It helps recruiters manage job openings, candidates, applications, and interviews in one centralized platform.

## Key Features

- **Job Management:** Create and manage job openings, departments, locations, salaries, and application deadlines.
- **Candidate Management:** Maintain candidate profiles, skills, education, experience, and contact details.
- **Application Management:** Track applications through Applied, Under Review, Shortlisted, Interview Scheduled, Selected, and Rejected stages.
- **Interview Management:** Schedule interviews, record feedback, assign scores, and manage interview statuses.
- **Job Listing Component:** Custom Lightning Web Component (LWC) for searching and filtering jobs, viewing job details, submitting applications, and checking application status.

## Salesforce Technologies Used

| Technology | Purpose |
|---|---|
| Salesforce Lightning Experience | User interface |
| Apex | Business logic |
| Apex Triggers | Data validation and automation |
| SOQL | Query Salesforce records |
| Lightning Web Components | Custom job listing interface |
| Salesforce Flows | Record automation |
| Validation Rules | Data integrity |
| Reports and Dashboards | Recruitment analytics |
| Role Hierarchy and Sharing Rules | Record-level security |

## Data Model

The project contains four custom objects:

- **Job__c:** Stores job openings and job details.
- **Candidate__c:** Stores candidate information.
- **Application__c:** Connects candidates with jobs and tracks application progress.
- **Interview__c:** Stores interview schedules, feedback, and scores.

### Relationships

- Application has a lookup relationship with Candidate.
- Application has a lookup relationship with Job.
- Interview has a lookup relationship with Candidate.
- Interview has a lookup relationship with Application.

## Automation and Business Logic

- Automatically populates the application date.
- Prevents duplicate applications for the same job.
- Allows applications only for open jobs.
- Prevents inactive, blacklisted, or hired candidates from applying.
- Updates candidate status to Hired when an application is selected.
- Automatically updates application status based on interview progress and scores.
- Prevents duplicate and conflicting interview schedules.
- Validates interview scores and completed interview feedback.
- Automatically closes jobs after their application deadline using scheduled Apex.

## Reports and Dashboard

The project includes recruitment reports for:

- Candidates by Status
- Applications by Status
- Jobs by Department
- Upcoming Interviews

A centralized **TalentTrack Recruitment Dashboard** provides a visual overview of recruitment activity.

## Security and Access Management

- Configured Organization-Wide Defaults (OWD).
- Implemented role hierarchy.
- Created a Recruitment Team profile.
- Configured criteria-based sharing rules.
- Applied object-level and field-level security.

## Apex Testing

- Application Trigger Test Class
- Interview Trigger Test Class
- 29 test methods passed.
- 0 test failures.
- 86% org-wide Apex code coverage at the time of testing.

## Project Structure

```text
force-app/
└── main/
    └── default/
        ├── applications/
        ├── classes/
        ├── flexipages/
        ├── flows/
        ├── layouts/
        ├── lwc/
        │   └── jobListing/
        ├── objects/
        ├── tabs/
        └── triggers/



## Learning Outcomes
This project demonstrates practical experience with Salesforce development, Apex programming, SOQL, Lightning Web Components, automation, security configuration, and recruitment business processes.

## Author
Developed as a Salesforce portfolio project.