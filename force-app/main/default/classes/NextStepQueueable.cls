/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable{
    public void execute(QueueableContext context) {

        List<Account> accts =[SELECT Id FROM Account WHERE Next_Step__c != null LIMIT 10];  // Get 10 accounts with Next Step populated

        List <Account> updatedAccounts = new List<Account>(); 

        for (Account acc : accts){
            acc.Next_Step__c = null;
            updatedAccounts.add(acc); 
        }
    update updatedAccounts; 

    List<Id> accountIds = new List<Id>(); 

    for (Account acc : accts) {
        accountIds.add(acc.Id); 
    }

    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId IN :accountIds]; 

    List<Opportunity> oppAccountId = new List<Opportunity>(); 

    for (Opportunity opp : opps) {
        opp.NextStep = null; 
        oppAccountId.add(opp); 
    }
    update oppAccountId; 

}

    // Method to queue the job
    public static void enqueueJob() {
        System.enqueueJob(new NextStepQueueable()); // If there are any accounts, queue the job using System.enqueueJob
    }
}
  