@isTest
private class ApplicationTriggerTest {

    // Helper: Create a Job
    private static Job__c createJob(String title, String status) {

        Job__c job = new Job__c(
            Job_Title__c = title,
            Department__c = 'IT',
            Location__c = 'Mumbai',
            Salary__c = 350000,
            Job_Type__c = 'Full - Time',
            Job_Status__c = status,
            Experience_Required__c = 'Fresher'
        );

        insert job;
        return job;
    }


    // Helper: Create a Candidate
    private static Candidate__c createCandidate(String firstName, String lastName, String email){

        Candidate__c candidate = new Candidate__c(
            First_Name__c = firstName,
            Last_Name__c = lastName,
            Email__c = email,
            Phone__c = '9876543210',
            Education__c = 'M.Sc.',
            Experience_Years__c = 0,
            Candidate_Status__c = 'Active'
        );

        insert candidate;
        return candidate;
    }


    // TEST 1: One Candidate becomes Hired
    @isTest
    static void testCandidateStatusChangesToHired() {

        Job__c job = createJob('Java Developer', 'Open');

        Candidate__c candidate = createCandidate(
            'Test', 'Candidate', 'test@example.com'
        );

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Under Review'
        );

        insert app;

        app.Application_Status__c = 'Selected';

        Test.startTest();
        update app;
        Test.stopTest();

        Candidate__c updatedCandidate = [
            SELECT Candidate_Status__c
            FROM Candidate__c
            WHERE Id = :candidate.Id
        ];

        System.assertEquals('Hired', updatedCandidate.Candidate_Status__c);
    }


    // TEST 2: Multiple Candidates become Hired
    @isTest
    static void testMultipleApplicationsUpdateCandidatesToHired() {

        Job__c job = createJob('Java Developer', 'Open');

        List<Candidate__c> candidates = new List<Candidate__c>();

        for (Integer i = 1; i <= 3; i++) {

            candidates.add(new Candidate__c(
                First_Name__c = 'Bulk',
                Last_Name__c = 'Candidate ' + i,
                Email__c = 'bulk' + i + '@example.com',
                Phone__c = '987654321' + i,
                Education__c = 'M.Sc.',
                Experience_Years__c = 0,
                Candidate_Status__c = 'Active'
            ));
        }

        insert candidates;

        List<Application__c> applications = new List<Application__c>();

        for (Candidate__c candidate : candidates) {

            applications.add(new Application__c(
                Candidate__c = candidate.Id,
                Job__c = job.Id,
                Application_Status__c = 'Under Review'
            ));
        }

        insert applications;

        for (Application__c app : applications) {
            app.Application_Status__c = 'Selected';
        }

        Test.startTest();
        update applications;
        Test.stopTest();

        Set<Id> candidateIds = new Set<Id>();

        for (Candidate__c candidate : candidates) {
            candidateIds.add(candidate.Id);
        }

        List<Candidate__c> updatedCandidates = [
            SELECT Id, Candidate_Status__c
            FROM Candidate__c
            WHERE Id IN :candidateIds
        ];

        System.assertEquals(3, updatedCandidates.size());

        for (Candidate__c candidate : updatedCandidates) {

            System.assertEquals(
                'Hired',
                candidate.Candidate_Status__c
            );
        }
    }


    // TEST 3: Duplicate Application is blocked
    @isTest
    static void testDuplicateApplicationIsBlocked() {

        Job__c job = createJob('Java Developer', 'Open');

        Candidate__c candidate = createCandidate(
            'Duplicate', 'Candidate', 'duplicate@example.com'
        );

        Application__c firstApp = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Applied'
        );

        insert firstApp;

        Application__c secondApp = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Applied'
        );

        Test.startTest();

        Database.SaveResult result = Database.insert(
            secondApp,
            false
        );

        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'already applied for this Job'
            )
        );
    }


    // TEST 4: Applications for Closed and On Hold Jobs are blocked
    @isTest
    static void testApplicationsForUnavailableJobsAreBlocked() {

        Job__c closedJob = createJob('Closed Java Developer', 'Closed');

        Job__c onHoldJob = createJob('On Hold Python Developer', 'On Hold');

        Candidate__c candidate1 = createCandidate('Closed', 'Job Candidate', 'closed@example.com');

        Candidate__c candidate2 = createCandidate('OnHold', 'Job Candidate', 'onhold@example.com');

        Application__c closedApplication = new Application__c(
            Candidate__c = candidate1.Id,
            Job__c = closedJob.Id,
            Application_Status__c = 'Applied'
        );

        Application__c onHoldApplication = new Application__c(
            Candidate__c = candidate2.Id,
            Job__c = onHoldJob.Id,
            Application_Status__c = 'Applied'
        );

        Test.startTest();

        Database.SaveResult closedResult = Database.insert(closedApplication, false);

        Database.SaveResult onHoldResult = Database.insert(onHoldApplication, false);

        Test.stopTest();

        System.assertEquals(false, closedResult.isSuccess());
        System.assertEquals(false, onHoldResult.isSuccess());

        System.assert(
            closedResult.getErrors()[0].getMessage().contains(
                'only be submitted for Open Jobs'
            )
        );

        System.assert(
            onHoldResult.getErrors()[0].getMessage().contains(
                'only be submitted for Open Jobs'
            )
        );
    }


    // TEST 5: Existing Application can be updated
    // even after its Job is closed
    @isTest
    static void testExistingApplicationCanBeUpdatedAfterJobCloses() {

        Job__c job = createJob('Java Developer', 'Open');

        Candidate__c candidate = createCandidate(
            'Existing', 'Applicant', 'existing@example.com'
        );

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Applied'
        );

        insert app;

        // Close the Job
        job.Job_Status__c = 'Closed';
        update job;

        // Update the existing Application status
        app.Application_Status__c = 'Under Review';

        Test.startTest();
        update app;
        Test.stopTest();

        Application__c updatedApp = [
            SELECT Application_Status__c
            FROM Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals('Under Review', updatedApp.Application_Status__c);
    }


    @isTest
    static void testInactiveCandidateApplicationIsBlocked() {

        // Create an Open Job
        Job__c job = createJob('Java Developer', 'Open');

        // Create an Active Candidate
        Candidate__c candidate = createCandidate(
            'Inactive',
            'Candidate',
            'inactive.test@example.com'
        );

        // Change Candidate Status to Inactive
        candidate.Candidate_Status__c = 'Inactive';
        update candidate;

        // Try to create an Application
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(app, false);
        Test.stopTest();

        // Verify that the Application is blocked
        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Inactive, Blacklisted, or Hired Candidates cannot apply for new Jobs.'
            )
        );
    }


    @isTest
    static void testBlacklistedCandidateApplicationIsBlocked() {

        // Create an Open Job
        Job__c job = createJob('Python Developer', 'Open');

        // Create an Active Candidate
        Candidate__c candidate = createCandidate(
            'Blacklisted',
            'Candidate',
            'blacklisted.test@example.com'
        );

        // Change Candidate Status to Blacklisted
        candidate.Candidate_Status__c = 'Blacklisted';
        update candidate;

        // Try to create an Application
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(app, false);
        Test.stopTest();

        // Verify that the Application is blocked
        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Inactive, Blacklisted, or Hired Candidates cannot apply for new Jobs.'
            )
        );
    }


    @isTest
    static void testExistingApplicationCanBeUpdatedAfterCandidateBecomesInactive() {

        // Create an Open Job and Active Candidate
        Job__c job = createJob('Java Tester', 'Open');

        Candidate__c candidate = createCandidate(
            'Existing',
            'Candidate',
            'existing.test@example.com'
        );

        // Create Application while Candidate is Active
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id
        );
        insert app;

        // Change Candidate Status to Inactive
        candidate.Candidate_Status__c = 'Inactive';
        update candidate;

        // Update the existing Application
        app.Application_Status__c = 'Under Review';

        Test.startTest();
        update app;
        Test.stopTest();

        // Verify that the Application was updated
        Application__c updatedApp = [
            SELECT Application_Status__c
            FROM Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            'Under Review',
            updatedApp.Application_Status__c
        );
    }



    @isTest
    static void testHiredCandidateCannotApplyForNewJob() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Hired',
            Last_Name__c = 'Candidate',
            Email__c = 'hiredcandidate@example.com',
            Phone__c = '9876543215',
            Candidate_Status__c = 'Hired'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Python Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Applied'
        );

        Test.startTest();

        try {
            insert app;
            System.assert(false, 'A Hired Candidate should not be allowed to apply.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Hired Candidates cannot apply'),
                'Expected the Hired Candidate validation error.'
            );
        }

        Test.stopTest();
    }



}