/**
 * Created by Steffen Naundorf on 31.05.2021.
 */

public without sharing class OpportunityHandler extends TriggerHandlerExtension {
  // Constructor
  public OpportunityHandler() {
    super();
  }

  //public override void bulkBefore() { }

  //public override void bulkAfter() {}

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

    List<OpportunityLineItem> lineItems = [
      SELECT Id, Plant__c, Product2.Family, Delivery_Location__c
      FROM OpportunityLineItem
      WHERE OpportunityId = :opportunity.Id
    ];

    for (OpportunityLineItem oli : lineItems) {
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

    List<Commitee_Opportunity_Junction__c> junctions = new List<Commitee_Opportunity_Junction__c>();
    for (Commitee__c commitee : commitees) {
      junctions.add(
        new Commitee_Opportunity_Junction__c(
          Opportunity__c = opportunity.Id,
          Commitee__c = commitee.Id
        )
      );
    }
    insert junctions;
  }

  //public override void beforeDelete(SObject obj) { addToLoopCount();}

  //public override void afterInsert(SObject obj) { addToLoopCount(); }

  //public override void afterUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

  //public override void afterDelete(SObject obj) { addToLoopCount();}

  //public override void andFinally() { }
}
