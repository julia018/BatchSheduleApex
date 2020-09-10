@isTest
private with sharing class AccountTotalAmountCounterTest {
    
    @testSetup static void setup() {
        // create 6 accounts
        List<Account> accountList = new List<Account>(); 
        List<Opportunity> opptyList = new List<Opportunity>(); 
        Account parentAcc = null;
        for(Integer i = 0; i < 6; i++) {
            Account acc = new Account(Name = 'TestAcc' + Datetime.now(), ParentId = (parentAcc != null ? parentAcc.Id : null));
            insert acc;     
            parentAcc = acc;       
            accountList.add(acc);
            opptyList.add(generateOpportunity(acc));            
        }
        insert opptyList;
        //insert accountList;
    }

    private static Opportunity generateOpportunity(Account acc) {
        Opportunity opp = new Opportunity(Name = 'Test' + Datetime.now(), AccountId = acc.Id, Amount = 200, StageName = 'Closed Won', CloseDate = Date.today().addMonths(-2));
        return opp;
    }

    @isTest static void updateAccountsTest() {
        Account acc = [SELECT Id, TotalAmount__c, (SELECT Amount FROM Opportunities WHERE StageName = 'Closed Won') FROM Account WHERE ParentId = null and Name LIKE 'TestAcc%'];
        System.assertEquals(null, acc.TotalAmount__c);
        Test.startTest();
        AccountTotalAmountCounter counter = new AccountTotalAmountCounter();
        List<Account> resultList = new List<Account>();        
        counter.updateAccounts(acc, resultList);
        Map<Id, Account> resultMap = new Map<Id, Account>(resultList);
        System.assertEquals(6 * 200, resultMap.get(acc.Id).TotalAmount__c);
        Test.stopTest();
    }

}
