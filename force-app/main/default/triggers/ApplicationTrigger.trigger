trigger ApplicationTrigger on Application__c (before insert, before update, after update){

    // BEFORE: Validate Job availability
    if (Trigger.isBefore) {

        // Check Job Availability
        ApplicationTriggerHandler.validateJobAvailability(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );

        // Check Candidate Eligibility
        ApplicationTriggerHandler.validateCandidateEligibility(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );

        // Prevent duplicate Applications
        ApplicationTriggerHandler.preventDuplicateApplications(
            Trigger.new
        );
    }

    // AFTER: Update Candidate status to Hired
    if (Trigger.isAfter && Trigger.isUpdate) {

        ApplicationTriggerHandler.updateCandidateStatus(
            Trigger.new,
            Trigger.oldMap
        );
    }
}