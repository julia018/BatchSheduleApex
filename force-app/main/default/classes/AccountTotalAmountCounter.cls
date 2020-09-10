global class AccountTotalAmountCounter implements Database.Batchable<SObject>{

    private List<Account> accountsToUpdate = new List<Account>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id, (SELECT Amount FROM Opportunities WHERE StageName = \'Closed Won\') FROM Account WHERE ParentId = null'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> records){
        // process each batch of records        
        for(Account acc: records) {
            updateAccounts(acc, accountsToUpdate);
        }
        upsert accountsToUpdate;
    }  

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        System.debug(accountsToUpdate.size() + ' accounts processed.');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        System.debug(job.NumberOfErrors + ' errors.');    
    } 

    private Decimal getOwnOpportunitiesAmount(List<Opportunity> opps) {
        Decimal sum = 0;
        for(Opportunity oppty: opps) {
            sum += oppty.Amount;
        }
        return sum;
    }   

    
    private Decimal countAccountOpportsAmount(Account acc) {
        Decimal newAccountTotalAmount = 0;
        for(Opportunity opp: acc.Opportunities) {
            newAccountTotalAmount += opp.Amount;
        } 
        return newAccountTotalAmount;
    }

    private List<Account> getChildAccounts(Id parentId) {
        return [SELECT Id, (SELECT Amount FROM Opportunities WHERE StageName = 'Closed Won') FROM Account WHERE ParentId = :parentId];
    }

    private void updateAccounts(Account acc, List<Account> updatedAccountList) {
        List<Opportunity> relatedOpps = acc.Opportunities;
        List<Account> childAccounts = getChildAccounts(acc.Id);
        if(childAccounts.size() == 0) {
            // account tree leaves
            acc.TotalAmount__c = countAccountOpportsAmount(acc);
            updatedAccountList.add(acc);
        } else {
            // not leaves
            Decimal childAmountsSum = 0;
            for(Account notLeafAccount: childAccounts) {
                updateAccounts(notLeafAccount, updatedAccountList);
                childAmountsSum += notLeafAccount.TotalAmount__c;
            }

            acc.TotalAmount__c = childAmountsSum + countAccountOpportsAmount(acc);
            updatedAccountList.add(acc);
        }
    }

    
    
}
