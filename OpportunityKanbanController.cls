public class OpportunityKanbanController {


    public static String OPPORTUNITY_MOVED = '{0} was moved successfully to {1}';
    
    public transient List<Schema.PicklistEntry> OpportunityStages      { get; set; }
    public transient List<Schema.PicklistEntry> OpportunityStagesNew   { get; set; }
    public Map<String, List<Opportunity>> allOpportunity               { get; set; }
    public Map<String, Integer> totalDealCountMap                      { get; set; }
    public Map<String, Decimal> totalAmountMap                         { get; set; }
    public String OpportunityID                                        { get; set; }
    public Double oppAmountCount                                       { get; set; }
    
    public class UpdateStatus {
        public Boolean isSuccess;
        public String message;
    }
    
    public OpportunityKanbanController() {
        oppAmountCount = 0.00;
        totalDealCountMap = new Map<String, Integer>();
        totalAmountMap = new Map<String, Decimal>();
        OpportunityStagesNew = Opportunity.StageName.getDescribe().getPicklistValues();
        OpportunityStages = new List<Schema.PicklistEntry>();
        For(Schema.PicklistEntry sch : OpportunityStagesNew){
            If(sch.getValue()!='Closed Lost')OpportunityStages.add(sch);
        }
        fetchOpportunity();
    }
    
    public PageReference deleteOpportunity() {
        System.debug('#### OpportunityID = '+OpportunityID);
        Delete [Select Id From Opportunity Where Id=:OpportunityID];
        //fetchOpportunity();
        return null;
    }
    
    public boolean displayPopup {get; set;}     
    
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }
    
    @RemoteAction
    public static UpdateStatus updateOpportunityStatus( Id OpportunityID, String newOppStatus ) {
        Opportunity opportunityDetails = [
            SELECT  Id,Name FROM Opportunity WHERE   Id = :OpportunityID ];
        
        opportunityDetails.StageName = newOppStatus;
        UPDATE opportunityDetails;
        
        UpdateStatus updatedOpportunityDetails = new UpdateStatus();
        updatedOpportunityDetails.isSuccess    = true;
        updatedOpportunityDetails.message      = String.format( OPPORTUNITY_MOVED, new List<String>{ opportunityDetails.Name, newOppStatus } );
        //fetchOpportunity();
        return updatedOpportunityDetails;
    }
    
    private void fetchOpportunity() {
        
        List<Opportunity> Opportunitys = [SELECT  Id, Name, Amount, CloseDate, Account.Name,AccountId, StageName, (select Id, OwnerID, Owner.Name, Subject FROM OpenActivities) 
                                                  FROM Opportunity Where  STAGENAME!='Closed Lost' LIMIT 200];
        allOpportunity = new Map<String, List<Opportunity>>();
        
        /*System.debug('#### Opportunitys = '+Opportunitys);
        System.debug('#### OpportunitysStatuses = '+OpportunityStages);*/
        
        for( Opportunity opp : Opportunitys ) {
            if( !allOpportunity.containsKey( opp.Stagename ) ) {
                allOpportunity.put( opp.Stagename, new List<Opportunity>{ opp } );
            } else if(allOpportunity.containsKey( opp.Stagename )){
                allOpportunity.get( opp.Stagename ).add( opp );
            }
            
            /* Count Deal for every stage */
            If(!totalDealCountMap.containsKey(opp.Stagename)){
                totalDealCountMap.put( opp.Stagename, 1 );
            }else IF(totalDealCountMap.containsKey(opp.Stagename)){
                totalDealCountMap.put( opp.Stagename, totalDealCountMap.get(opp.Stagename)+1 );
            }
            /* End */
            
            /* Count Deal Amount for every stage */
            If(!totalAmountMap.containsKey(opp.Stagename)){
                totalAmountMap.put( opp.Stagename, opp.Amount);
            }else IF(totalAmountMap.containsKey(opp.Stagename)){
                Decimal newAmount = totalAmountMap.get(opp.Stagename); Decimal totalAmount = newAmount+opp.Amount;
                totalAmountMap.put( opp.Stagename,  totalAmount);
            }
            /* End */
            
        }
        /*System.debug('#### totalAmountMap = '+totalAmountMap);
        System.debug('#### allOpportunity = '+allOpportunity);*/
        
        For(Schema.PicklistEntry str : OpportunityStages){
            
            if( !allOpportunity.containsKey( str.getValue() ) ) {
                System.debug('#### Adding Opportunity Object');
                allOpportunity.put( str.getValue(), new List<Opportunity>{  } );
            }
            
            IF(!totalDealCountMap.containsKey(str.getValue())){
                totalDealCountMap.put( str.getValue(), 0 );
            }
            
            IF(!totalAmountMap.containsKey(str.getValue())){
                totalAmountMap.put( str.getValue(), 000 );
            }
            
        }
        
        System.debug('#### allOpportunity = '+allOpportunity);
        
    }
}