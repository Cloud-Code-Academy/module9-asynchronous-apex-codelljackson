/*
 * NextStepBatch Class Description:
 * 
 * Implementing the 'Database.Batchable' interface allows you to define a job that can be broken into smaller batches.
 * Update the Next Step field on all accounts and opportunities in the org to 'Batching the next meetings together.' 
 * Send an email to all active users
 * 
 * Benefits of using Batch Apex:
 * 
 * 1. Large Data Volumes: Batch Apex is specifically tailored to handle large data volumes (LDV). It allows processing of 
 *     records in batches, making it suitable for bulk processing, especially when dealing with millions of records.
 * 2. Avoid Governor Limits: By splitting the transaction into smaller batches, you can perform operations on a large number 
 *     of records without hitting governor limits.
 * 3. Flexible Scheduling: Batch classes can be scheduled to run at specified intervals, providing flexibility in terms of 
 *     when the processing occurs.
 * 4. Stateful Execution: Supports stateful execution, so you can maintain state across batch transactions by implementing the 
 *    `Database.Stateful` interface.
 * 5. Built-in Retry Mechanism: If a batch fails, Salesforce provides built-in mechanisms to retry the batch.
 * 6. Asynchronous Processing: Operations are executed asynchronously, ensuring that the user is not blocked while the batch is 
 *     processing.
 * 
 * For a more detailed understanding and best practices, refer to the official Salesforce documentation: 
 *    https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch.htm
 * 
 * Note: This class contains placeholders and commented sections that need to be updated with actual logic for querying and updating 
 *  records.
 */
public with sharing class NextStepBatch implements Database.Batchable<sObject>{

    public Database.QueryLocator start(Database.BatchableContext bc){ 
        
        return Database.getQueryLocator([SELECT Id FROM Account]); // Query for all accounts and return the query locator. and // Update null with the query locator
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){

        final String BATCH_NEXT_STEP = 'Batching the next meetings together.';

        List<Account> accountsToUpdate = new List<Account>(); // Update the Next Step field on each record in the batch scope.

        for (Account acc : scope){// Loop through the scope account records
            
            acc.Next_Step__c = BATCH_NEXT_STEP; // Set the Next Step field to 'Batching the next meetings together.'
            accountsToUpdate.add(acc); 
        }
            if (!accountsToUpdate.isEmpty()){ // Update the account records
                update accountsToUpdate; // Update the account records in this batch scope
        }
    
        List<Id> accountIds = new List<Id>(); //Create a new list of Ids for the accounts
        
        for (Account acc : scope) { // Loop through the accounts in the batch scope
            accountIds.add(acc.Id); 
        }
        List<Opportunity> oppsToUpdate = [SELECT Id FROM Opportunity WHERE AccountId IN : accountIds]; // Query for all opportunities related to the accounts in this batch scope

        List<Opportunity> opportunityToUpdate = new List<Opportunity>(); 

        for (Opportunity opp : oppsToUpdate) {// Loop through the opportunity records
            opp.NextStep = BATCH_NEXT_STEP; // Set the Next Step field to 'Batching the next meetings together.'
            opportunityToUpdate.add(opp);

        }
        if (!opportunityToUpdate.isEmpty()) {
            update opportunityToUpdate; // Update the opportunity records
        }    
    }
    
    public void finish(Database.BatchableContext bc){
        final List<User> USERS = [SELECT Id, Name, Email FROM User WHERE IsActive = true AND (NOT Email LIKE 'autoproc%')]; // DO NOT CHANGE

        List<String> usersEmailAddress = new List<String>(); // Get the email addresses of all active users

        for (User activeUser : USERS){  
            usersEmailAddress.add(activeUser.Email);
        }
        Set<String> emailSet = new Set<String>(usersEmailAddress); // Pass the set of active user emails to the sendEmailToActiveUsers method
        sendEmailToActiveUsers(emailSet); 
    }


    // Helper method to send an email to all emails in the set
    private void sendEmailToActiveUsers(Set<String> emails){
        
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(emails));
            mail.setSubject('Next Step Batch Complete');
            mail.setPlainTextBody('The next step batch has completed.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
        
    }
}
