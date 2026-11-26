global class JobDeadlineScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        // Get today's date
        Date todayDate = Date.today();

        // Find Open Jobs whose deadlines have passed
        List<Job__c> expiredJobs = [
            SELECT Id, Job_Status__c, Application_Deadline__c
            FROM Job__c
            WHERE Job_Status__c = 'Open'
            AND Application_Deadline__c < :todayDate
        ];

        // Close expired Jobs
        for (Job__c job : expiredJobs) {
            job.Job_Status__c = 'Closed';
        }

        // Save all changes together
        if (!expiredJobs.isEmpty()) {
            update expiredJobs;
        }
    }
}