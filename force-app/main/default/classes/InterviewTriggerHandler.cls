public class InterviewTriggerHandler {

    // 1. Update Application Status when Interview is Completed
    public static void updateApplicationStatus(
        List<Interview__c> newInterviews,
        Map<Id, Interview__c> oldInterviews
    ) {

        Set<Id> applicationIds = new Set<Id>();

        for (Interview__c interview : newInterviews) {

            Interview__c oldInterview = oldInterviews.get(interview.Id);

            if (
                interview.Interview_Status__c == 'Completed' &&
                oldInterview.Interview_Status__c != 'Completed' &&
                interview.Application__c != null
            ) {
                applicationIds.add(interview.Application__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        List<Application__c> applications = [
            SELECT Id, Application_Status__c
            FROM Application__c
            WHERE Id IN :applicationIds
        ];

        for (Application__c app : applications) {

            if (app.Application_Status__c == 'Interview Scheduled') {
                app.Application_Status__c = 'Under Review';
            }
        }

        if (!applications.isEmpty()) {
            update applications;
        }
    }


    // 2. Validate Interview Score
    public static void validateInterviewScore(
        List<Interview__c> interviews
    ) {

        for (Interview__c interview : interviews) {

            if (
                interview.Interview_Score__c != null &&
                (
                    interview.Interview_Score__c < 0 ||
                    interview.Interview_Score__c > 10
                )
            ) {
                interview.addError(
                    'Interview Score must be between 0 and 10.'
                );
            }
        }
    }

    // 3. Prevent Duplicate Interviews
    public static void preventDuplicateInterviews(List<Interview__c> newInterviews, Map<Id, Interview__c> oldInterviews) {

        Set<Id> applicationIds = new Set<Id>();
        Set<Date> interviewDates = new Set<Date>();

        for (Interview__c interview : newInterviews) {

            if (
                interview.Application__c == null ||
                interview.Interview_Date__c == null ||
                (
                    interview.Interview_Status__c != 'Scheduled' &&
                    interview.Interview_Status__c != 'Rescheduled'
                )
            ) {
                continue;
            }

            if (oldInterviews != null) {
                Interview__c oldInterview = oldInterviews.get(interview.Id);

                if (
                    oldInterview.Application__c == interview.Application__c &&
                    oldInterview.Interview_Date__c == interview.Interview_Date__c &&
                    (
                        oldInterview.Interview_Status__c == 'Scheduled' ||
                        oldInterview.Interview_Status__c == 'Rescheduled'
                    )
                ) {
                    continue;
                }
            }

            applicationIds.add(interview.Application__c);
            interviewDates.add(interview.Interview_Date__c);
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        List<Interview__c> existingInterviews = [
            SELECT Id, Application__c, Interview_Date__c
            FROM Interview__c
            WHERE Application__c IN :applicationIds
            AND Interview_Date__c IN :interviewDates
            AND Interview_Status__c IN ('Scheduled', 'Rescheduled')
        ];

        Set<String> existingKeys = new Set<String>();

        for (Interview__c existing : existingInterviews) {

            String key =
                String.valueOf(existing.Application__c) + '-' +
                String.valueOf(existing.Interview_Date__c);

            existingKeys.add(key);
        }

        Set<String> processedKeys = new Set<String>();

        for (Interview__c interview : newInterviews) {

            if (
                interview.Application__c == null ||
                interview.Interview_Date__c == null ||
                (
                    interview.Interview_Status__c != 'Scheduled' &&
                    interview.Interview_Status__c != 'Rescheduled'
                )
            ) {
                continue;
            }

            if (oldInterviews != null) {
                Interview__c oldInterview = oldInterviews.get(interview.Id);

                if (
                    oldInterview.Application__c == interview.Application__c &&
                    oldInterview.Interview_Date__c == interview.Interview_Date__c &&
                    (
                        oldInterview.Interview_Status__c == 'Scheduled' ||
                        oldInterview.Interview_Status__c == 'Rescheduled'
                    )
                ) {
                    continue;
                }
            }

            String key =
                String.valueOf(interview.Application__c) + '-' +
                String.valueOf(interview.Interview_Date__c);

            if (
                existingKeys.contains(key) ||
                processedKeys.contains(key)
            ) {
                interview.addError(
                    'An active Interview already exists for this Application on this date.'
                );
            } else {
                processedKeys.add(key);
            }
        }
    }

    // 4. Validate Completed Interview Feedback
    public static void validateCompletedInterviewFeedback(
        List<Interview__c> interviews
    ) {

        for (Interview__c interview : interviews) {

            if (
                interview.Interview_Status__c == 'Completed' &&
                String.isBlank(interview.Interview_Feedback__c)
            ) {
                interview.addError(
                    'Please provide Interview Feedback before marking the interview as Completed.'
                );
            }
        }
    }


    // 5. Update Application Status Based on Interview Score
    public static void updateApplicationBasedOnInterviewScore(
        List<Interview__c> newInterviews
    ) {

        Set<Id> applicationIds = new Set<Id>();

        // Collect Applications from completed Interviews
        for (Interview__c interview : newInterviews) {

            if (
                interview.Interview_Status__c == 'Completed' &&
                interview.Application__c != null &&
                interview.Interview_Score__c != null
            ) {
                applicationIds.add(interview.Application__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        // Query related Applications
        List<Application__c> applications = [
            SELECT Id, Application_Status__c
            FROM Application__c
            WHERE Id IN :applicationIds
        ];

        Map<Id, Application__c> applicationMap =
            new Map<Id, Application__c>(applications);

        // Apply status based on Interview Score
        for (Interview__c interview : newInterviews) {

            if (
                interview.Interview_Status__c == 'Completed' &&
                interview.Interview_Score__c != null &&
                applicationMap.containsKey(interview.Application__c)
            ) {

                Application__c app =
                    applicationMap.get(interview.Application__c);

                if (interview.Interview_Score__c >= 8) {
                    app.Application_Status__c = 'Shortlisted';
                }
                else if (interview.Interview_Score__c < 5) {
                    app.Application_Status__c = 'Rejected';
                }
                else {
                    app.Application_Status__c = 'Under Review';
                }
            }
        }

        // Save all Applications together
        update applications;
    }



    // 6. Prevent Interviews for Rejected or Withdrawn Applications
    public static void validateApplicationEligibility(List<Interview__c> interviews) {

        Set<Id> applicationIds = new Set<Id>();

        for (Interview__c interview : interviews) {
            if (interview.Application__c != null) {
                applicationIds.add(interview.Application__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        Map<Id, Application__c> applicationMap = new Map<Id, Application__c>([
                SELECT Id, Application_Status__c
                FROM Application__c
                WHERE Id IN :applicationIds
            ]);

        for (Interview__c interview : interviews) {

            Application__c app = applicationMap.get(interview.Application__c);

            if (app != null &&
                (   app.Application_Status__c == 'Rejected' ||
                    app.Application_Status__c == 'Withdrawn'
                )
            ) {
                interview.addError(
                    'Interviews cannot be scheduled for Rejected or Withdrawn Applications.'
                );
            }
        }
    }




    // 7. Prevent Interviews for Closed or On Hold Jobs
    public static void validateJobAvailabilityForInterview(
        List<Interview__c> interviews
    ) {

        Set<Id> applicationIds = new Set<Id>();

        for (Interview__c interview : interviews) {
            if (interview.Application__c != null) {
                applicationIds.add(interview.Application__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        Map<Id, Application__c> applicationMap =
            new Map<Id, Application__c>([
                SELECT Id, Job__c
                FROM Application__c
                WHERE Id IN :applicationIds
            ]);

        Set<Id> jobIds = new Set<Id>();

        for (Application__c app : applicationMap.values()) {
            if (app.Job__c != null) {
                jobIds.add(app.Job__c);
            }
        }

        if (jobIds.isEmpty()) {
            return;
        }

        Map<Id, Job__c> jobMap =
            new Map<Id, Job__c>([
                SELECT Id, Job_Status__c
                FROM Job__c
                WHERE Id IN :jobIds
            ]);

        for (Interview__c interview : interviews) {

            Application__c app =
                applicationMap.get(interview.Application__c);

            if (app == null || app.Job__c == null) {
                continue;
            }

            Job__c job = jobMap.get(app.Job__c);

            if (
                job != null &&
                (
                    job.Job_Status__c == 'Closed' ||
                    job.Job_Status__c == 'On Hold'
                )
            ) {
                interview.addError(
                    'Interviews cannot be scheduled for Closed or On Hold Jobs.'
                );
            }
        }
    }

    // 8. Prevent Multiple Active Interviews for the Same Application
    public static void preventMultipleActiveInterviews(List<Interview__c> interviews) {

        Set<Id> applicationIds = new Set<Id>();

        // Collect Applications with active Interviews
        for (Interview__c interview : interviews) {
            if (
                interview.Application__c != null &&
                (
                    interview.Interview_Status__c == 'Scheduled' ||
                    interview.Interview_Status__c == 'Rescheduled'
                )
            ) {
                applicationIds.add(interview.Application__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        // Find existing active Interviews
        List<Interview__c> existingInterviews = [
            SELECT Id, Application__c
            FROM Interview__c
            WHERE Application__c IN :applicationIds
            AND Interview_Status__c IN ('Scheduled', 'Rescheduled')
        ];

        Map<Id, Set<Id>> activeInterviewIdsByApplication =
            new Map<Id, Set<Id>>();

        for (Interview__c existing : existingInterviews) {
            if (!activeInterviewIdsByApplication.containsKey(existing.Application__c)) {
                activeInterviewIdsByApplication.put(
                    existing.Application__c,
                    new Set<Id>()
                );
            }

            activeInterviewIdsByApplication.get(existing.Application__c).add(existing.Id);
        }

        // Check new or updated Interviews
        Set<Id> processedApplications = new Set<Id>();

        for (Interview__c interview : interviews) {

            if (
                interview.Application__c == null ||
                (
                    interview.Interview_Status__c != 'Scheduled' &&
                    interview.Interview_Status__c != 'Rescheduled'
                )
            ) {
                continue;
            }

            Boolean anotherActiveInterviewExists = false;

            if (activeInterviewIdsByApplication.containsKey(interview.Application__c)) {
                for (Id existingId : activeInterviewIdsByApplication.get(interview.Application__c)) {
                    if (existingId != interview.Id) {
                        anotherActiveInterviewExists = true;
                        break;
                    }
                }
            }

            if (
                anotherActiveInterviewExists ||
                processedApplications.contains(interview.Application__c)
            ) {
                interview.addError(
                    'Only one active Interview is allowed for an Application.'
                );
            } else {
                processedApplications.add(interview.Application__c);
            }
        }
    }



    // 9. Automatically Mark Changed Interviews as Rescheduled
    public static void markInterviewAsRescheduled(
        List<Interview__c> newInterviews,
        Map<Id, Interview__c> oldInterviews
    ) {

        for (Interview__c interview : newInterviews) {

            Interview__c oldInterview =
                oldInterviews.get(interview.Id);

            if (
                oldInterview != null &&
                oldInterview.Interview_Status__c == 'Scheduled' &&
                interview.Interview_Status__c == 'Scheduled' &&
                oldInterview.Interview_Date__c != interview.Interview_Date__c
            ) {
                interview.Interview_Status__c = 'Rescheduled';
            }
        }
    }




    // 10. Prevent Interviewer Schedule Conflicts
    public static void preventInterviewerScheduleConflicts(
        List<Interview__c> interviews,
        Map<Id, Interview__c> oldInterviews
    ) {

        Set<String> interviewerNames = new Set<String>();
        Set<Date> interviewDates = new Set<Date>();

        for (Interview__c interview : interviews) {

            if (
                String.isBlank(interview.Interviewer_Name__c) ||
                interview.Interview_Date__c == null ||
                (
                    interview.Interview_Status__c != 'Scheduled' &&
                    interview.Interview_Status__c != 'Rescheduled'
                )
            ) {
                continue;
            }

            Interview__c oldInterview = oldInterviews == null
                ? null
                : oldInterviews.get(interview.Id);

            // Skip updates that do not change the schedule
            if (
                oldInterview != null &&
                oldInterview.Interview_Status__c != 'Cancelled' &&
                oldInterview.Interview_Status__c != 'Completed' &&
                oldInterview.Interviewer_Name__c == interview.Interviewer_Name__c &&
                oldInterview.Interview_Date__c == interview.Interview_Date__c
            ) {
                continue;
            }

            interviewerNames.add(interview.Interviewer_Name__c.trim());
            interviewDates.add(interview.Interview_Date__c);
        }

        if (interviewerNames.isEmpty()) {
            return;
        }

        List<Interview__c> existingInterviews = [
            SELECT Id, Interviewer_Name__c, Interview_Date__c
            FROM Interview__c
            WHERE Interviewer_Name__c IN :interviewerNames
            AND Interview_Date__c IN :interviewDates
            AND Interview_Status__c IN ('Scheduled', 'Rescheduled')
        ];

        Set<String> existingSchedules = new Set<String>();

        for (Interview__c existing : existingInterviews) {
            existingSchedules.add(
                existing.Interviewer_Name__c.trim().toLowerCase() +
                '-' + String.valueOf(existing.Interview_Date__c)
            );
        }

        Set<String> processedSchedules = new Set<String>();

        for (Interview__c interview : interviews) {

            if (
                String.isBlank(interview.Interviewer_Name__c) ||
                interview.Interview_Date__c == null ||
                (
                    interview.Interview_Status__c != 'Scheduled' &&
                    interview.Interview_Status__c != 'Rescheduled'
                )
            ) {
                continue;
            }

            Interview__c oldInterview = oldInterviews == null
                ? null
                : oldInterviews.get(interview.Id);

            if (
                oldInterview != null &&
                oldInterview.Interview_Status__c != 'Cancelled' &&
                oldInterview.Interview_Status__c != 'Completed' &&
                oldInterview.Interviewer_Name__c == interview.Interviewer_Name__c &&
                oldInterview.Interview_Date__c == interview.Interview_Date__c
            ) {
                continue;
            }

            String scheduleKey =
                interview.Interviewer_Name__c.trim().toLowerCase() +
                '-' + String.valueOf(interview.Interview_Date__c);

            if (
                existingSchedules.contains(scheduleKey) ||
                processedSchedules.contains(scheduleKey)
            ) {
                interview.addError(
                    'This interviewer already has an active Interview scheduled on this date.'
                );
            } else {
                processedSchedules.add(scheduleKey);
            }
        }
    }




}