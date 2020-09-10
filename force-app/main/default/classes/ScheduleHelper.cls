public with sharing class ScheduleHelper {

    private static final String cronExpr = '0 0 22 ? * 6 *';

    public static void scheduleJob() {
        AccTotalAmountBatchScheduler scheduler = new AccTotalAmountBatchScheduler();
        System.schedule('Recount Accounts Toatal Amount', cronExpr, scheduler);
    }
}
