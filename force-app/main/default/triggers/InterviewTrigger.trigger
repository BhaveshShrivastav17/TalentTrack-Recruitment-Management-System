trigger InterviewTrigger on Interview__c (before insert, before update, after update){

    if (Trigger.isBefore) {

        if (Trigger.isUpdate) {
            InterviewTriggerHandler.markInterviewAsRescheduled(Trigger.new, Trigger.oldMap);
        }

        InterviewTriggerHandler.preventInterviewerScheduleConflicts(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);

        InterviewTriggerHandler.validateInterviewScore(Trigger.new);

        InterviewTriggerHandler.validateCompletedInterviewFeedback(Trigger.new);

        InterviewTriggerHandler.validateApplicationEligibility(Trigger.new);

        InterviewTriggerHandler.validateJobAvailabilityForInterview(Trigger.new);

        InterviewTriggerHandler.preventDuplicateInterviews(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);

        InterviewTriggerHandler.preventMultipleActiveInterviews(Trigger.new);
    }


    if (Trigger.isAfter && Trigger.isUpdate) {

        InterviewTriggerHandler.updateApplicationStatus(Trigger.new, Trigger.oldMap);

        InterviewTriggerHandler.updateApplicationBasedOnInterviewScore(Trigger.new);

    }

}