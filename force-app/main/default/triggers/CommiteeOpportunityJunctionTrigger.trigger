/**
 * Created by Steffen Naundorf on 01.06.2021.
 */

trigger CommiteeOpportunityJunctionTrigger on Commitee_Opportunity_Junction__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerFactory.executeTriggerHandlers(
    Commitee_Opportunity_Junction__c.SObjectType
  );
}
