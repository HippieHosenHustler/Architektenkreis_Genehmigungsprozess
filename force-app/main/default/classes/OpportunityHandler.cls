/**
 * Created by Steffen Naundorf on 31.05.2021.
 */

public without sharing class OpportunityHandler extends TriggerHandlerExtension {

  Map<Id, Commitee__c> committees = new Map<Id, Commitee__c>();
  Map<Id, List<OpportunityLineItem>> lineItemsByOppIds = new Map<Id, List<OpportunityLineItem>>();
  List<Commitee_Opportunity_Junction__c> junctionsToInsert = new List<Commitee_Opportunity_Junction__c>();

  List<Approval.ProcessSubmitRequest> approvalRequestList = new List<Approval.ProcessSubmitRequest>();

  // Constructor
  public OpportunityHandler() {
    super();
    committees = new Map<Id, Commitee__c>([
            SELECT Id, Account__c, Plant__c, Delivery_Location__c, Product_Family__c, (
                    SELECT User__c
                    FROM Commitee_Assignments__r
            )
            FROM Commitee__c
    ]);
  }

  public override void bulkBefore() {
    Set<Id> oppIds = new Set<Id>();
    for (Opportunity opp : (List<Opportunity>) Trigger.new) {
      oppIds.add(opp.Id);
    }

    List<OpportunityLineItem> lineItems = [
            SELECT Id, Plant__c, Product2.Family, Delivery_Location__c, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
    ];

    for (OpportunityLineItem oli : lineItems) {
      if (!lineItemsByOppIds.containsKey(oli.OpportunityId)) {
        lineItemsByOppIds.put(oli.OpportunityId, new List<OpportunityLineItem>());
      }
      lineItemsByOppIds.get(oli.OpportunityId).add(oli);
    }
  }

  public override void bulkAfter() {
    insert junctionsToInsert;

    for (Commitee_Opportunity_Junction__c junction : junctionsToInsert) {
      // Users that need to approve this
      List<Id> userIds = new List<Id>();
      Commitee__c commitee = committees.get(junction.Commitee__c);
      for (Commitee_Assignment__c ass : commitee.Commitee_Assignments__r) {
        userIds.add(ass.User__c);
      }

      for (Id userId : userIds) {
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(junction.Id);
        approvalRequest.setNextApproverIds(new List<Id>{userId});
        approvalRequestList.add(approvalRequest);
      }

      Approval.process(approvalRequestList);
    }
  }

  //public override void beforeInsert(SObject obj) { addToLoopCount(); }

  public override void beforeUpdate(SObject oldObj, SObject obj) {
    addToLoopCount();
    Opportunity opportunityNew = (Opportunity) obj;

    if (
            opportunityNew.Priority_Transition__c == 'Important' ||
                    opportunityNew.Priority_Transition__c == 'Very Important'
            ) {
      lockAndStartApproval(opportunityNew);
    } else {
      opportunityNew.Priority__c = opportunityNew.Priority_Transition__c;
    }
  }

  private void lockAndStartApproval(Opportunity opportunity) {
    opportunity.Is_Locked__c = true;

    Set<String> deliveryLocations = new Set<String>();
    Set<String> productFamilies = new Set<String>();
    Set<Id> plantIds = new Set<Id>();

    for (OpportunityLineItem oli : lineItemsByOppIds.get(opportunity.Id)) {
      deliveryLocations.add(oli.Delivery_Location__c);
      productFamilies.add(oli.Product2.Family);
      plantIds.add(oli.Plant__c);
    }

    for (Commitee__c commitee : committees.values()) {
      if (commitee.Account__c == opportunity.AccountId || deliveryLocations.contains(commitee.Delivery_Location__c) || productFamilies.contains(commitee.Product_Family__c) || plantIds.contains(commitee.Plant__c)) {
        junctionsToInsert.add(
                new Commitee_Opportunity_Junction__c(
                        Opportunity__c = opportunity.Id,
                        Commitee__c = commitee.Id,
                        Approval_Round__c = 1
                )
        );
      }

    }
  }

  //public override void beforeDelete(SObject obj) { addToLoopCount();}

  //public override void afterInsert(SObject obj) { addToLoopCount(); }

  //public override void afterUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

  //public override void afterDelete(SObject obj) { addToLoopCount();}

  //public override void andFinally() { }
}
