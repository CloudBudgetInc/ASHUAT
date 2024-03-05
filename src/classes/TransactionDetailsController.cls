public class TransactionDetailsController {
    public Integer totalSize { get; private set; } 
    private Integer limitSize = 50; // number of items per page    
    public List<c2g__codaTransactionLineItem__c> transactionItems { get; set; }
    public Integer pageNumber { get; set; }

    public TransactionDetailsController() {        
        pageNumber = 1;
        calculateTotalSize();
        fetchTransactions();
    }

    private void fetchTransactions() {
        String company = ApexPages.currentPage().getParameters().get('company');
        String year = ApexPages.currentPage().getParameters().get('year');
        String key = ApexPages.currentPage().getParameters().get('key');

        Integer offset = (pageNumber - 1) * limitSize;
        transactionItems = FinReviewController.transactionsVF(company, year, key, limitSize, offset);
    }

    private void calculateTotalSize() {
        String company = ApexPages.currentPage().getParameters().get('company');
        String year = ApexPages.currentPage().getParameters().get('year');
        String key = ApexPages.currentPage().getParameters().get('key');

        totalSize = [SELECT count() FROM c2g__codaTransactionLineItem__c WHERE Account_Subaccount__c = :key AND c2g__OwnerCompany__r.Key__c = :company AND c2g__Transaction__r.c2g__Period__r.Fiscal_Year_Text__c = :year];
    }

    public Integer getTotalPages() {
        if (totalSize == 0) {
            return 1; 
        }
        return (Integer) Math.ceil(totalSize / (Decimal) limitSize);
    }

    public void nextPage() {
        pageNumber++;
        fetchTransactions();
    }

    public void previousPage() {
        if (pageNumber > 1) {
            pageNumber--;
            fetchTransactions();
        }
    }

    public Boolean getPrevAvailable() {
        return pageNumber > 1;
    }

    public Boolean getNextAvailable() {
        return transactionItems.size() == limitSize;
    }
}