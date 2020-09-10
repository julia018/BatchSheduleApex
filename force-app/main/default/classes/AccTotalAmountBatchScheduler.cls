public with sharing class AccTotalAmountBatchScheduler implements Schedulable{
    
    public void execute(SchedulableContext ctx) {
        AccountTotalAmountCounter batchObject = new AccountTotalAmountCounter(); 
        Database.executeBatch(batchObject);
    }
}
