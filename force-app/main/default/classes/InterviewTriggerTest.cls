@isTest
public class InterviewTriggerTest {

    @isTest
    static void testCompletedInterviewUpdatesApplication() {

        // Create an Active Candidate
        Candidate__c candidate = new Candidate__c(
            Name = 'Test Candidate',
            First_Name__c = 'Test',
            Last_Name__c = 'Candidate',
            Email__c = 'interview.test@example.com',
            Phone__c = '9876543210',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        // Create an Open Job
        Job__c job = new Job__c(
            Name = 'Test Java Developer',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        // Create an Application
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        // Create a Scheduled Interview
        Interview__c interview = new Interview__c(
            Name = 'Technical Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert interview;

        // Complete the Interview
        Test.startTest();

        interview.Interview_Status__c = 'Completed';
        interview.Interview_Feedback__c = 'Good performance in the interview.';
        update interview;

        Test.stopTest();

        // Verify Application Status
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
    static void testCancelledInterviewDoesNotUpdateApplication() {

        // Create Candidate
        Candidate__c candidate = new Candidate__c(
            Name = 'Cancelled Test Candidate',
            First_Name__c = 'Cancelled',
            Last_Name__c = 'Candidate',
            Email__c = 'cancelled.test@example.com',
            Phone__c = '9876543213',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        // Create Open Job
        Job__c job = new Job__c(
            Name = 'Test Python Developer',
            Job_Title__c = 'Python Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        // Create Application
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        // Create Scheduled Interview
        Interview__c interview = new Interview__c(
            Name = 'HR Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled'
        );
        insert interview;

        // Cancel the Interview
        Test.startTest();

        interview.Interview_Status__c = 'Cancelled';
        update interview;

        Test.stopTest();

        // Verify Application Status remains unchanged
        Application__c updatedApp = [
            SELECT Application_Status__c
            FROM Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            'Interview Scheduled',
            updatedApp.Application_Status__c
        );
    }


    @isTest
    static void testInvalidInterviewScoreIsBlocked() {

        // Create Candidate
        Candidate__c candidate = new Candidate__c(
            Name = 'Score Test Candidate',
            First_Name__c = 'Score',
            Last_Name__c = 'Candidate',
            Email__c = 'score.test@example.com',
            Phone__c = '9876543214',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        // Create Open Job
        Job__c job = new Job__c(
            Name = 'Score Test Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        // Create Application
        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        // Create Interview with invalid score
        Interview__c interview = new Interview__c(
            Name = 'Score Validation Test',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interview_Score__c = 11
        );

        Test.startTest();

        Database.SaveResult result = Database.insert(interview, false);

        Test.stopTest();

        // Verify invalid score is rejected
        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Interview Score must be between 0 and 10.'
            )
        );
    }


    @isTest
    static void testValidInterviewScoreIsAccepted() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Valid Score Candidate',
            First_Name__c = 'Valid',
            Last_Name__c = 'Candidate',
            Email__c = 'valid.score@example.com',
            Phone__c = '9876543215',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Valid Score Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Name = 'Valid Score Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interview_Score__c = 8
        );

        Test.startTest();
        insert interview;
        Test.stopTest();

        System.assertNotEquals(null, interview.Id);
    }


    @isTest
    static void testDuplicateInterviewOnSameDateIsBlocked() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Duplicate Test Candidate',
            First_Name__c = 'Duplicate',
            Last_Name__c = 'Candidate',
            Email__c = 'duplicate.test@example.com',
            Phone__c = '9876543216',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Duplicate Test Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Date interviewDate = Date.today();

        // Create the first Interview
        Interview__c firstInterview = new Interview__c(
            Name = 'First Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert firstInterview;

        // Try creating another Interview on the same date
        Interview__c secondInterview = new Interview__c(
            Name = 'Second Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondInterview, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors().size() > 0,
            'A duplicate active Interview should be blocked.'
        );
    }

    @isTest
    static void testDifferentDateActiveInterviewIsBlocked() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Different Date Candidate',
            First_Name__c = 'Different',
            Last_Name__c = 'Candidate',
            Email__c = 'different.date@example.com',
            Phone__c = '9876543217',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Different Date Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c firstInterview = new Interview__c(
            Name = 'First Round',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert firstInterview;

        Interview__c secondInterview = new Interview__c(
            Name = 'Second Round',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today().addDays(1),
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondInterview, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Only one active Interview is allowed for an Application.'
            )
        );
    }




    @isTest
    static void testCancelledInterviewAllowsNewInterviewOnSameDate() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Cancelled Interview Candidate',
            First_Name__c = 'Cancelled',
            Last_Name__c = 'Interview',
            Email__c = 'cancelled.duplicate@example.com',
            Phone__c = '9876543218',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Cancelled Interview Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Date interviewDate = Date.today();

        // Create first Interview
        Interview__c firstInterview = new Interview__c(
            Name = 'Cancelled First Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert firstInterview;

        // Cancel the first Interview
        firstInterview.Interview_Status__c = 'Cancelled';
        update firstInterview;

        // Create another Interview on the same date
        Interview__c secondInterview = new Interview__c(
            Name = 'Replacement Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled'
        );

        Test.startTest();
        insert secondInterview;
        Test.stopTest();

        System.assertNotEquals(null, secondInterview.Id);
    }



    @isTest
    static void testExistingInterviewCanBeUpdatedWithoutDuplicateError() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Update Test Candidate',
            First_Name__c = 'Update',
            Last_Name__c = 'Candidate',
            Email__c = 'update.interview@example.com',
            Phone__c = '9876543219',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Update Test Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Name = 'Update Test Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert interview;

        // Update feedback without changing Application or Date
        interview.Interview_Feedback__c = 'Good technical knowledge';
        interview.Interview_Score__c = 8;

        Test.startTest();
        update interview;
        Test.stopTest();

        Interview__c updatedInterview = [
            SELECT Interview_Feedback__c, Interview_Score__c
            FROM Interview__c
            WHERE Id = :interview.Id
        ];

        System.assertEquals(
            'Good technical knowledge',
            updatedInterview.Interview_Feedback__c
        );

        System.assertEquals(
            8,
            updatedInterview.Interview_Score__c
        );
    }



    @isTest
    static void testHighInterviewScoreShortlistsApplication() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Candidate',
            Email__c = 'highscore@example.com',
            Phone__c = '9876543210',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );
        insert interview;

        interview.Interview_Status__c = 'Completed';
        interview.Interview_Feedback__c = 'Excellent performance';
        interview.Interview_Score__c = 9;
        update interview;

        Application__c updatedApp = [
            SELECT Application_Status__c
            FROM Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            'Shortlisted',
            updatedApp.Application_Status__c
        );
    }




    @isTest
    static void testMediumInterviewScoreKeepsApplicationUnderReview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Medium',
            Last_Name__c = 'Candidate',
            Email__c = 'mediumscore@example.com',
            Phone__c = '9876543213',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );
        insert interview;

        interview.Interview_Status__c = 'Completed';
        interview.Interview_Feedback__c = 'Average performance';
        interview.Interview_Score__c = 6.5;
        update interview;

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
    static void testLowInterviewScoreRejectsApplication() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Low',
            Last_Name__c = 'Candidate',
            Email__c = 'lowscore@example.com',
            Phone__c = '9876543214',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );
        insert interview;

        interview.Interview_Status__c = 'Completed';
        interview.Interview_Feedback__c = 'Poor performance';
        interview.Interview_Score__c = 4;
        update interview;

        Application__c updatedApp = [
            SELECT Application_Status__c
            FROM Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals(
            'Rejected',
            updatedApp.Application_Status__c
        );
    }



    @isTest
    static void testRejectedApplicationCannotHaveInterview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Rejected',
            Last_Name__c = 'Candidate',
            Email__c = 'rejectedtest@example.com',
            Phone__c = '9876543216',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Rejected'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );

        Database.SaveResult result = Database.insert(interview, false);

        System.assertEquals(
            false,
            result.isSuccess(),
            'An Interview should not be allowed for a Rejected Application.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Rejected or Withdrawn Applications'
            )
        );
    }




    @isTest
    static void testWithdrawnApplicationCannotHaveInterview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Withdrawn',
            Last_Name__c = 'Candidate',
            Email__c = 'withdrawntest@example.com',
            Phone__c = '9876543217',
            Candidate_Status__c = 'Active'
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
            Application_Status__c = 'Withdrawn'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );

        Database.SaveResult result = Database.insert(interview, false);

        System.assertEquals(
            false,
            result.isSuccess(),
            'An Interview should not be allowed for a Withdrawn Application.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Rejected or Withdrawn Applications'
            )
        );
    }




    @isTest
    static void testClosedJobCannotHaveInterview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Closed',
            Last_Name__c = 'JobCandidate',
            Email__c = 'closedjobtest@example.com',
            Phone__c = '9876543218',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Applied'
        );
        insert app;

        // Close the Job after creating the Application
        job.Job_Status__c = 'Closed';
        update job;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );

        Database.SaveResult result = Database.insert(interview, false);

        System.assertEquals(
            false,
            result.isSuccess(),
            'An Interview should not be allowed for a Closed Job.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Closed or On Hold Jobs'
            )
        );
    }




    @isTest
    static void testOnHoldJobCannotHaveInterview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'OnHold',
            Last_Name__c = 'JobCandidate',
            Email__c = 'onholdjobtest@example.com',
            Phone__c = '9876543219',
            Candidate_Status__c = 'Active'
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
        insert app;

        // Put the Job On Hold after creating the Application
        job.Job_Status__c = 'On Hold';
        update job;

        Interview__c interview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Test Interviewer'
        );

        Database.SaveResult result = Database.insert(interview, false);

        System.assertEquals(
            false,
            result.isSuccess(),
            'An Interview should not be allowed for an On Hold Job.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Closed or On Hold Jobs'
            )
        );
    }



    @isTest
    static void testInterviewAutomaticallyBecomesRescheduled() {

        Candidate__c candidate = new Candidate__c(
            Name = 'Reschedule Candidate',
            First_Name__c = 'Reschedule',
            Last_Name__c = 'Candidate',
            Email__c = 'reschedule.test@example.com',
            Phone__c = '9876543218',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Name = 'Reschedule Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c interview = new Interview__c(
            Name = 'Reschedule Interview',
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert interview;

        // Change the Interview Date
        interview.Interview_Date__c = Date.today().addDays(2);

        Test.startTest();
        update interview;
        Test.stopTest();

        // Verify the status changed automatically
        Interview__c updatedInterview = [
            SELECT Interview_Status__c
            FROM Interview__c
            WHERE Id = :interview.Id
        ];

        System.assertEquals(
            'Rescheduled',
            updatedInterview.Interview_Status__c
        );
    }



    @isTest
    static void testSameInterviewerCannotHaveTwoInterviewsOnSameDate() {

        Candidate__c candidate1 = new Candidate__c(
            Name = 'Interviewer Test Candidate One',
            First_Name__c = 'Interviewer',
            Last_Name__c = 'One',
            Email__c = 'interviewer.one@example.com',
            Phone__c = '9876543220',
            Candidate_Status__c = 'Active'
        );
        insert candidate1;

        Candidate__c candidate2 = new Candidate__c(
            Name = 'Interviewer Test Candidate Two',
            First_Name__c = 'Interviewer',
            Last_Name__c = 'Two',
            Email__c = 'interviewer.two@example.com',
            Phone__c = '9876543221',
            Candidate_Status__c = 'Active'
        );
        insert candidate2;

        Job__c job = new Job__c(
            Name = 'Interviewer Conflict Job',
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app1 = new Application__c(
            Candidate__c = candidate1.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );

        Application__c app2 = new Application__c(
            Candidate__c = candidate2.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert new List<Application__c>{app1, app2};

        Date interviewDate = Date.today().addDays(1);

        Interview__c firstInterview = new Interview__c(
            Name = 'First Interview',
            Candidate__c = candidate1.Id,
            Application__c = app1.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Amit Verma'
        );
        insert firstInterview;

        Interview__c secondInterview = new Interview__c(
            Name = 'Second Interview',
            Candidate__c = candidate2.Id,
            Application__c = app2.Id,
            Interview_Date__c = interviewDate,
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Amit Verma'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondInterview, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'This interviewer already has an active Interview scheduled on this date.'
            )
        );
    }




    @isTest
    static void testCompletedInterviewAllowsNewInterview() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Completed',
            Last_Name__c = 'Test',
            Email__c = 'completed.test@example.com',
            Phone__c = '9876543230',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        Interview__c firstInterview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled'
        );
        insert firstInterview;

        // Complete the first Interview
        firstInterview.Interview_Status__c = 'Completed';
        firstInterview.Interview_Feedback__c = 'Good performance';
        update firstInterview;

        // Create another Interview for the same Application
        Interview__c secondInterview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today().addDays(1),
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(secondInterview, false);
        Test.stopTest();

        System.assertEquals(
            true,
            result.isSuccess(),
            'A Completed Interview should not block a new Interview.'
        );
    }



    @isTest
    static void testReactivatingCancelledInterviewIsBlocked() {

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'Reactivation',
            Last_Name__c = 'Test',
            Email__c = 'reactivation.test@example.com',
            Phone__c = '9876543231',
            Candidate_Status__c = 'Active'
        );
        insert candidate;

        Job__c job = new Job__c(
            Job_Title__c = 'Java Developer',
            Job_Status__c = 'Open'
        );
        insert job;

        Application__c app = new Application__c(
            Candidate__c = candidate.Id,
            Job__c = job.Id,
            Application_Status__c = 'Interview Scheduled'
        );
        insert app;

        // Create the first Interview
        Interview__c firstInterview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today(),
            Interview_Type__c = 'Technical',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Interviewer One'
        );
        insert firstInterview;

        // Cancel the first Interview
        firstInterview.Interview_Status__c = 'Cancelled';
        update firstInterview;

        // Create another active Interview for the same Application
        Interview__c secondInterview = new Interview__c(
            Candidate__c = candidate.Id,
            Application__c = app.Id,
            Interview_Date__c = Date.today().addDays(1),
            Interview_Type__c = 'HR',
            Interview_Status__c = 'Scheduled',
            Interviewer_Name__c = 'Interviewer Two'
        );
        insert secondInterview;

        // Try to reactivate the first Interview
        firstInterview.Interview_Status__c = 'Scheduled';

        Test.startTest();
        Database.SaveResult result = Database.update(firstInterview, false);
        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'A Cancelled Interview must not be reactivated when another active Interview exists.'
        );

        System.assert(
            result.getErrors()[0].getMessage().contains(
                'Only one active Interview is allowed for an Application.'
            ),
            'The expected active Interview validation error should be returned.'
        );
    }




}