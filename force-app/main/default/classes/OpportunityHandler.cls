/**
 * Created by Steffen Naundorf on 31.05.2021.
 */

public without sharing class OpportunityHandler extends TriggerHandlerExtension {

  Map<Id, List<OpportunityLineItem>> lineItemsByOppIds = new Map<Id, List<OpportunityLineItem>>();
  List<Commitee_Opportunity_Junction__c> junctionsToInsert = new List<Commitee_Opportunity_Junction__c>();
  List<Commitee_Opportunity_Junction__c> junctionsToUpdate = new List<Commitee_Opportunity_Junction__c>();

  // Constructor
  public OpportunityHandler() {
    super();
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
    update junctionsToUpdate;
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

    List<Commitee__c> commitees = [
      SELECT Id
      FROM Commitee__c
      WHERE
        Account__c = :opportunity.AccountId
        OR Delivery_Location__c IN :deliveryLocations
        OR Plant__c IN :plantIds
        OR Product_Family__c IN :productFamilies
    ];

    for (Commitee__c commitee : commitees) {
      junctionsToInsert.add(
        new Commitee_Opportunity_Junction__c(
          Opportunity__c = opportunity.Id,
          Commitee__c = commitee.Id
        )
      );
    }
  }

  //public override void beforeDelete(SObject obj) { addToLoopCount();}

  //public override void afterInsert(SObject obj) { addToLoopCount(); }

  //public override void afterUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

  //public override void afterDelete(SObject obj) { addToLoopCount();}

  //public override void andFinally() { }
}
