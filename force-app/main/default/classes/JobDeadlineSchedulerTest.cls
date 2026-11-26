@IsTest
private class JobDeadlineSchedulerTest {

    @IsTest
    static void testExpiredJobsAreClosed() {

        List<Job__c> jobs = new List<Job__c>();

        jobs.add(new Job__c(
            Name = 'Expired Job',
            Job_Title__c = 'Expired Job',
            Job_Status__c = 'Open',
            Application_Deadline__c = Date.today().addDays(-1)
        ));

        jobs.add(new Job__c(
            Name = 'Today Job',
            Job_Title__c = 'Today Job',
            Job_Status__c = 'Open',
            Application_Deadline__c = Date.today()
        ));

        jobs.add(new Job__c(
            Name = 'Future Job',
            Job_Title__c = 'Future Job',
            Job_Status__c = 'Open',
            Application_Deadline__c = Date.today().addDays(5)
        ));

        jobs.add(new Job__c(
            Name = 'On Hold Job',
            Job_Title__c = 'On Hold Job',
            Job_Status__c = 'On Hold',
            Application_Deadline__c = Date.today().addDays(-1)
        ));

        insert jobs;

        Test.startTest();

        System.schedule(
            'Test Job Deadline Scheduler',
            '0 0 0 * * ?',
            new JobDeadlineScheduler()
        );

        Test.stopTest();

        Map<String, Job__c> savedJobs = new Map<String, Job__c>();

        for (Job__c job : [
            SELECT Job_Title__c, Job_Status__c
            FROM Job__c
        ]) {
            savedJobs.put(job.Job_Title__c, job);
        }

        System.assertEquals(
            'Closed',
            savedJobs.get('Expired Job').Job_Status__c
        );

        System.assertEquals(
            'Open',
            savedJobs.get('Today Job').Job_Status__c
        );

        System.assertEquals(
            'Open',
            savedJobs.get('Future Job').Job_Status__c
        );

        System.assertEquals(
            'On Hold',
            savedJobs.get('On Hold Job').Job_Status__c
        );
    }
}