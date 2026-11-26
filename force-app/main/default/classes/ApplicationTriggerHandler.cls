public class ApplicationTriggerHandler {

    // FEATURE 1: Prevent duplicate Applications
    public static void preventDuplicateApplications(List<Application__c> newApplications){

        Set<Id> candidateIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();

        for (Application__c app : newApplications) {
            if (app.Candidate__c != null && app.Job__c != null) {
                candidateIds.add(app.Candidate__c);
                jobIds.add(app.Job__c);
            }
        }

        if (candidateIds.isEmpty() || jobIds.isEmpty()) {
            return;
        }

        List<Application__c> existingApplications = [
            SELECT Id, Candidate__c, Job__c
            FROM Application__c
            WHERE Candidate__c IN :candidateIds
            AND Job__c IN :jobIds
        ];

        Map<String, Set<Id>> existingPairs = new Map<String, Set<Id>>();

        for (Application__c existingApp : existingApplications) {

            String key = String.valueOf(existingApp.Candidate__c)
                + '-' + String.valueOf(existingApp.Job__c);

            if (!existingPairs.containsKey(key)) {
                existingPairs.put(key, new Set<Id>());
            }

            existingPairs.get(key).add(existingApp.Id);
        }

        Set<String> processedPairs = new Set<String>();

        for (Application__c app : newApplications) {

            if (app.Candidate__c == null || app.Job__c == null) {
                continue;
            }

            String key = String.valueOf(app.Candidate__c)
                + '-' + String.valueOf(app.Job__c);

            Boolean duplicateFound = false;

            if (existingPairs.containsKey(key)) {
                for (Id existingId : existingPairs.get(key)) {
                    if (existingId != app.Id) {
                        duplicateFound = true;
                        break;
                    }
                }
            }

            if (processedPairs.contains(key)) {
                duplicateFound = true;
            }

            if (duplicateFound) {
                app.addError(
                    'This Candidate has already applied for this Job.'
                );
            } else {
                processedPairs.add(key);
            }
        }
    }


    // FEATURE 2: Prevent Applications for closed or On Hold Jobs
    public static void validateJobAvailability(List<Application__c> newApplications, Map<Id, Application__c> oldApplications){

        Set<Id> jobIds = new Set<Id>();

        for (Application__c app : newApplications) {

            // Skip if Candidate or Job is not selected
            if (app.Job__c == null) {
                continue;
            }

            // During updates, validate only if Job has changed
            if (oldApplications != null) {

                Application__c oldApp = oldApplications.get(app.Id);

                if (oldApp.Job__c == app.Job__c) {
                    continue;
                }
            }

            jobIds.add(app.Job__c);
        }

        if (jobIds.isEmpty()) {
            return;
        }

        Map<Id, Job__c> jobs = new Map<Id, Job__c>([
            SELECT Id, Job_Status__c
            FROM Job__c
            WHERE Id IN :jobIds
        ]);

        for (Application__c app : newApplications) {

            if (app.Job__c == null) {
                continue;
            }

            if (oldApplications != null) {

                Application__c oldApp = oldApplications.get(app.Id);

                if (oldApp.Job__c == app.Job__c) {
                    continue;
                }
            }

            Job__c relatedJob = jobs.get(app.Job__c);

            if (
                relatedJob != null &&
                relatedJob.Job_Status__c != 'Open'
            ) {
                app.addError(
                    'Applications can only be submitted for Open Jobs.'
                );
            }
        }
    }


    // FEATURE 3: Update Candidate Status to Hired
    public static void updateCandidateStatus(List<Application__c> newApplications, Map<Id, Application__c> oldApplications){

        Set<Id> candidateIds = new Set<Id>();

        for (Application__c app : newApplications) {

            Application__c oldApp = oldApplications.get(app.Id);

            if (app.Application_Status__c == 'Selected' && oldApp.Application_Status__c != 'Selected' && app.Candidate__c != null){
                candidateIds.add(app.Candidate__c);
            }
        }

        if (!candidateIds.isEmpty()) {

            List<Candidate__c> candidatesToUpdate = [
                SELECT Id, Candidate_Status__c
                FROM Candidate__c
                WHERE Id IN :candidateIds
            ];

            for (Candidate__c candidate : candidatesToUpdate) {
                candidate.Candidate_Status__c = 'Hired';
            }

            update candidatesToUpdate;
        }
    }


    // FEATURE 4: Prevent Inactive or Blacklisted Candidates
    public static void validateCandidateEligibility(List<Application__c> newApplications, Map<Id, Application__c> oldApplications){

        Set<Id> candidateIds = new Set<Id>();

        // Collect Candidate IDs
        for (Application__c app : newApplications) {

            if (app.Candidate__c == null) {
                continue;
            }

            // During update, check only when Candidate changes
            if (oldApplications != null) {

                Application__c oldApp = oldApplications.get(app.Id);

                if (oldApp.Candidate__c == app.Candidate__c) {
                    continue;
                }
            }

            candidateIds.add(app.Candidate__c);
        }

        if (candidateIds.isEmpty()) {
            return;
        }

        // Retrieve Candidate Status
        Map<Id, Candidate__c> candidates = new Map<Id, Candidate__c>([
                SELECT Id, Candidate_Status__c
                FROM Candidate__c
                WHERE Id IN :candidateIds
            ]);

        // Validate Candidate eligibility
        for (Application__c app : newApplications) {

            if (app.Candidate__c == null) {
                continue;
            }

            if (oldApplications != null) {

                Application__c oldApp = oldApplications.get(app.Id);

                if (oldApp.Candidate__c == app.Candidate__c) {
                    continue;
                }
            }

            Candidate__c candidate = candidates.get(app.Candidate__c);

            if (candidate != null &&
                (
                    candidate.Candidate_Status__c == 'Inactive' ||
                    candidate.Candidate_Status__c == 'Blacklisted' ||
                    candidate.Candidate_Status__c == 'Hired'
                )
            ){
                app.addError(
                    'Inactive, Blacklisted, or Hired Candidates cannot apply for new Jobs.'
                );
            }
        }
    }


}