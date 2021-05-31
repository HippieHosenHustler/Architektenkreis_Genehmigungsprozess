/**
 * Created by Steffen Naundorf on 31.05.2021.
 */

trigger OpportunityTrigger on Opportunity(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerFactory.executeTriggerHandlers(Opportunity.SObjectType);
}
