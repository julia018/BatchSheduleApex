@isTest
private with sharing class AccountTotalAmountCounterTest {

    private static Decimal OPPORTUNITY_AMOUNT = 200;
    
    @testSetup static void setup() {
        // create 6 accounts
        List<Opportunity> opptyList = new List<Opportunity>(); 
        Account parentAcc = null;
        for (Integer i = 0; i < 6; i++) {
            Account acc = new Account(Name = 'TestAcc' + i + Datetime.now(), 
                                      ParentId = (parentAcc != null ? parentAcc.Id : null));
            if (i == 2) {
                Account acc1 = new Account(Name = 'TestAcc' + Datetime.now(), 
                                      ParentId = (parentAcc != null ? parentAcc.Id : null));
                insert acc1;
                opptyList.add(generateOpportunity(acc1));     
            }                                            
            // insert is used in loop because its Id is needed as ParentId for next account
            insert acc;     
            parentAcc = acc;      
            opptyList.add(generateOpportunity(acc));            
        }
        insert opptyList;
    }

    private static Opportunity generateOpportunity(Account acc) {
        Opportunity opp = new Opportunity(Name = 'Test' + Datetime.now(), 
                                          AccountId = acc.Id, 
                                          Amount = OPPORTUNITY_AMOUNT, 
                                          StageName = 'Closed Won', 
                                          CloseDate = Date.today().addMonths(-2));
        return opp;
    }

    @isTest static void updateAccountsTest() { 
        Account accRoot = [SELECT Id, TotalAmount__c, (SELECT Amount 
                                                       FROM Opportunities 
                                                       WHERE StageName = 'Closed Won') 
                           FROM Account 
                           WHERE ParentId = null and Name LIKE 'TestAcc%'];
        Account accLeafParent = [SELECT Id, TotalAmount__c, (SELECT Amount 
                                                       FROM Opportunities 
                                                       WHERE StageName = 'Closed Won') 
                           FROM Account 
                           WHERE Name LIKE 'TestAcc4%'];
        System.assertEquals(null, accRoot.TotalAmount__c);
        Test.startTest();
        AccountTotalAmountCounter counter = new AccountTotalAmountCounter();
        List<Account> resultList = new List<Account>();     
        List<Account> topLevelAccounts = new List<Account>();
        topLevelAccounts.add(accRoot);   
        counter.updateAccounts(topLevelAccounts, resultList);
        Map<Id, Account> resultMap = new Map<Id, Account>(resultList);
        System.assertEquals(2 * OPPORTUNITY_AMOUNT, resultMap.get(accLeafParent.Id).TotalAmount__c);
        // root = TestAccount0 
        // TestAccount1 has 2 child accounts, so root account has sort of 6 child opportunities and 1 own 
        System.assertEquals(7 * OPPORTUNITY_AMOUNT, resultMap.get(accRoot.Id).TotalAmount__c);
        Test.stopTest();
    }

    @isTest static void addClosedOpportunityTest() {
        Account accRoot = [SELECT Id, TotalAmount__c, (SELECT Amount 
                                                       FROM Opportunities 
                                                       WHERE StageName = 'Closed Won') 
                           FROM Account 
                           WHERE ParentId = null and Name LIKE 'TestAcc%'];
        Account accLeafParent = [SELECT Id, TotalAmount__c, (SELECT Amount 
                                                       FROM Opportunities 
                                                       WHERE StageName = 'Closed Won') 
                           FROM Account 
                           WHERE Name LIKE 'TestAcc4%'];

        Account accLeaf = [SELECT Id, TotalAmount__c, (SELECT Amount 
                                                       FROM Opportunities 
                                                       WHERE StageName = 'Closed Won') 
                           FROM Account 
                           WHERE Name LIKE 'TestAcc5%'];
                           
                           
        System.assertEquals(null, accRoot.TotalAmount__c);
        Test.startTest();
        AccountTotalAmountCounter counter = new AccountTotalAmountCounter();
        List<Account> resultList = new List<Account>();   
        List<Account> topLevelAccountList = new List<Account>(); 
        topLevelAccountList.add(accRoot);
        counter.updateAccounts(topLevelAccountList, resultList);
        upsert resultList;
        Map<Id, Account> resultMap = new Map<Id, Account>(resultList);
        Decimal accLeafParentStartAmount = resultMap.get(accLeafParent.Id).TotalAmount__c;
        Decimal accRootStartAmount = resultMap.get(accRoot.Id).TotalAmount__c;

        // insert closed won opportunity for leaf
        Opportunity newOpp = generateOpportunity(accLeaf);
        insert newOpp;
        
        List<Account> newResultList = new List<Account>(); 
        counter.updateAccounts(topLevelAccountList, newResultList);
        upsert newResultList;

        // check new total amount
        Account accLeafParentUpdated = [SELECT Id, TotalAmount__c 
                                        FROM Account 
                                        WHERE Name LIKE 'TestAcc4%'];

        Decimal newLeafParentTotalAmount = accLeafParentUpdated.TotalAmount__c;
        Decimal newRootTotalAmount = accRoot.TotalAmount__c;

        System.assertEquals(accLeafParentStartAmount + OPPORTUNITY_AMOUNT, newLeafParentTotalAmount);
        System.assertEquals(accRootStartAmount + OPPORTUNITY_AMOUNT, newRootTotalAmount);

        Test.stopTest();
        
    }



}
