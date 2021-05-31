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
    } else {
      opportunityNew.Priority__c = opportunityNew.Priority_Transition__c;
    }
  }

  //public override void beforeDelete(SObject obj) { addToLoopCount();}

  //public override void afterInsert(SObject obj) { addToLoopCount(); }

  //public override void afterUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

  //public override void afterDelete(SObject obj) { addToLoopCount();}

  //public override void andFinally() { }
}