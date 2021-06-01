/**
 * Created by Steffen Naundorf on 01.06.2021.
 */

public without sharing class CommiteeOpportunityJunctionHandler extends TriggerHandlerExtension {
  public static List<Id> oppIdsToCheck = new List<Id>();
  public CommiteeOpportunityJunctionHandler() {
    super();
  }

  //public override void bulkBefore() { }

  //public override void bulkAfter() { }

  //public override void beforeInsert(SObject obj) { addToLoopCount(); }

  //public override void beforeUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

  //public override void beforeDelete(SObject obj) { addToLoopCount();}

  //public override void afterInsert(SObject obj) { addToLoopCount(); }

  public override void afterUpdate(SObject oldObj, SObject obj) {
    addToLoopCount();
    Commitee_Opportunity_Junction__c junctionNew = (Commitee_Opportunity_Junction__c) obj;

    if (junctionNew.Is_Locked__c == true) {
      oppIdsToCheck.add(junctionNew.Opportunity__c);
    }
  }

  //public override void afterDelete(SObject obj) { addToLoopCount();}

  public override void andFinally() {
    if (oppIdsToCheck.size() > 0) {
      for (Id oppId : oppIdsToCheck) {
        checkAllRequests(oppId);
      }
    }
  }

  public void checkAllRequests(Id oppId) {
    Decimal approvalRound = [
      SELECT Id, Approval_Round__c
      FROM Commitee_Opportunity_Junction__c
      ORDER BY Approval_Round__c DESC
      LIMIT 1
    ]
    .Approval_Round__c;
    List<Commitee_Opportunity_Junction__c> requests = [
      SELECT Id, Is_Locked__c, Has_Approved__c, Opportunity__c
      FROM Commitee_Opportunity_Junction__c
      WHERE Opportunity__c = :oppId AND Approval_Round__c = :approvalRound
    ];

    Boolean allApproved = true;
    for (Commitee_Opportunity_Junction__c tempJunction : requests) {
      if (tempJunction.Is_Locked__c == true) {
        if (tempJunction.Has_Approved__c == false) {
          allApproved = false;
        }
      } else {
        return; //if at least one decision is outstanding, process will wait
      }
    }

    if (allApproved == true) {
      Opportunity opportunity = [
        SELECT Id, Priority_Transition__c, Priority__c
        FROM Opportunity
        WHERE Id = :oppId
      ];
      opportunity.Priority__c = opportunity.Priority_Transition__c;
      update opportunity;
    }
  }
}
