global class AccountTotalAmountCounter implements Database.Batchable<SObject>{

    private List<Account> accountsToUpdate = new List<Account>();

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator(
            'SELECT Id, (SELECT Amount FROM Opportunities WHERE StageName = \'Closed Won\') FROM Account WHERE ParentId = null'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> records){
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : records) {
            // list represents accounts for current level (for recursion)
            List<Account> levelAccounts = new List<Account>();
            levelAccounts.add(acc);
            // start recursion for parent acc
            updateAccounts(levelAccounts, accountsToUpdate);
        }
        upsert accountsToUpdate;
    }  

    global void finish(Database.BatchableContext bc){

        System.debug(accountsToUpdate.size() + ' accounts processed.');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        System.debug(job.NumberOfErrors + ' errors.');    
    } 

    @TestVisible private void updateAccounts(List<Account> currentLevelAccounts, List<Account> updatedAccountList) {
        
        // get accounts from level below
        List<Account> belowLevelAccounts = getAccountsByParentIdList(new Map<Id, Account>(currentLevelAccounts));
        if (belowLevelAccounts.size() != 0) {
            // not leaves - start recursion for updating below accounts
            updateAccounts(belowLevelAccounts, updatedAccountList);            
        } 
        // here all accounts below are updated
        for(Account acc: currentLevelAccounts) {
            updateAccountTotalAmount(acc, belowLevelAccounts);
        }
        updatedAccountList.addAll(currentLevelAccounts);
    }  
    
    private List<Account> getAccountsByParentIdList(Map<Id, Account> parentAccountsMap) {
        return [SELECT Id, ParentId, (SELECT Amount 
                            FROM Opportunities 
                            WHERE StageName = 'Closed Won') 
                FROM Account 
                WHERE ParentId in : parentAccountsMap.keySet()];
    }

    private void updateAccountTotalAmount(Account account, List<Account> updatedBelowLevelAccounts) {
        Decimal newTotalAmount = 0;
        for(Account updatedAccount: updatedBelowLevelAccounts) {            
            if(updatedAccount.ParentId.equals(account.Id)) {
                newTotalAmount += updatedAccount.TotalAmount__c;
            }
        }
        newTotalAmount += getOpportunitiesTotalAmount(account);
        account.TotalAmount__c = newTotalAmount;
    }

    private Decimal getOpportunitiesTotalAmount(Account acc) {
        Decimal result = 0;
        for(Opportunity opp: acc.Opportunities) {
            result += opp.Amount;
        }
        return result;
    }

    
    
    private void updateAccountTreeLeaves(List<Account> leavesAccounts) {
        for(Account leafAcount: leavesAccounts) {
            Decimal opportunitiesTotalAmount = 0;
            for(Opportunity opp: leafAcount.Opportunities) {
                opportunitiesTotalAmount += opp.Amount;
            }
            leafAcount.TotalAmount__c = opportunitiesTotalAmount;
        }
    }
    
}
