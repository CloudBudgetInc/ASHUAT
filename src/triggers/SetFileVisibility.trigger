//This trigger will automatically share files uploaded by community users so that they can view their own files
//At this time there is no way to do this through declarative automation
trigger SetFileVisibility on ContentDocumentLink (before insert) {
     for (ContentDocumentLink cdl : Trigger.new) {
          if (cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Contact') {
              String linkId = cdl.LinkedEntityId;
              List<User> cList = [SELECT Id FROM User WHERE ContactId = :linkId];
              if (cList.size() > 0){
                  cdl.visibility = 'AllUsers';
              }
          }
     }
}