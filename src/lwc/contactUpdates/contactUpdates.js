import { LightningElement, api, wire, track } from "lwc";
import ASH_Annual_Meeting__c from "@salesforce/schema/Contact.ASH_Annual_Meeting__c";
import ASH_Meeting_on_Hematologic_Malignancies__c from "@salesforce/schema/Contact.ASH_Meeting_on_Hematologic_Malignancies__c";
import Latest_in_Precision_Medicine_and_Immuno__c from "@salesforce/schema/Contact.Latest_in_Precision_Medicine_and_Immuno__c";
import Highlights_of_ASH__c from "@salesforce/schema/Contact.Highlights_of_ASH__c";
import ASH_Quality_Improvement_and_Clinical_Pra__c from "@salesforce/schema/Contact.ASH_Quality_Improvement_and_Clinical_Pra__c";
import Medical_Students__c from "@salesforce/schema/Contact.Medical_Students__c";
import Career_and_Training__c from "@salesforce/schema/Contact.Career_and_Training__c";
import Honorific_and_Mentor__c from "@salesforce/schema/Contact.Honorific_and_Mentor__c";
import Webinars_Webcasts_Podcasts__c from "@salesforce/schema/Contact.Webinars_Webcasts_Podcasts__c";
import Job_Center_Opportunities__c from "@salesforce/schema/Contact.Job_Center_Opportunities__c";
import Global_Opportunities__c from "@salesforce/schema/Contact.Global_Opportunities__c";
import Opportunities_for_Trainees__c from "@salesforce/schema/Contact.Opportunities_for_Trainees__c";
import Medical_education_and_recruitment__c from "@salesforce/schema/Contact.Medical_Education_and_Recruitment__c";
import Advance_Notice__c from "@salesforce/schema/Contact.Advance_Notice__c";
import Blood_Advances_Highlights__c from "@salesforce/schema/Contact.Blood_Advances_Highlights__c";
import This_Week_in_Blood__c from "@salesforce/schema/Contact.This_Week_in_Blood__c";
import ASH_Clinical_Trials__c from "@salesforce/schema/Contact.ASH_Clinical_Trials__c";
import TraineE_News__c from "@salesforce/schema/Contact.TraineE_News__c";
import ASH_Practice_Update__c from "@salesforce/schema/Contact.ASH_Practice_Update__c";
import ASH_Newslink__c from "@salesforce/schema/Contact.ASH_Newslink__c";
import Sickle_Cell_Disease__c from "@salesforce/schema/Contact.Sickle_Cell_Disease__c";
import The_Hematologist__c from "@salesforce/schema/Contact.The_Hematologist__c";
import ASH_News_Daily__c from "@salesforce/schema/Contact.ASH_News_Daily__c";
import HasOptedOutOfEmail from "@salesforce/schema/Contact.HasOptedOutOfEmail";
import On_Point_Blood_Neoplasia__c from "@salesforce/schema/Contact.On_Point_Blood_Neoplasia__c";
import On_Point_Blood_VTH__c	 from "@salesforce/schema/Contact.On_Point_Blood_VTH__c";
import Email_Subscriptions_Last_Updated_Date__c from "@salesforce/schema/Contact.Email_Subscriptions_Last_Updated_Date__c";
import ASH_Member__c from "@salesforce/schema/Contact.ASH_Member__c";
import Membership_Status__c from "@salesforce/schema/Contact.Membership_Status__c";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";
import ASH_MEMBER from "@salesforce/schema/User.Contact.ASH_Member__c";

export default class ContactUpdates extends LightningElement {
@track checkbox1;
@track checkbox2;
@track checkbox3;
@track checkbox4;
@track checkbox5;
@track checkbox6;
@track checkbox7;
@track checkbox8;
@track checkbox9;
@track checkbox10;
@track checkbox11;
@track checkbox12;
@track checkbox13;
@track checkbox14;
@track checkbox15;
@track checkbox16;
@track checkbox17;
@track checkbox18;
@track checkbox19;
@track checkbox20;
@track checkbox21;
@track checkbox22;
@track checkbox23;
@track checkbox25;
@track checkbox26;
@track checkbox27;
checkbox24 = false;

  memberStatus;
  subscribeAll;
  unSubscribeAll;
  currentDateTime;
  
  ASH_Annual_Meeting__c = ASH_Annual_Meeting__c;
  ASH_Meeting_on_Hematologic_Malignancies__c = ASH_Meeting_on_Hematologic_Malignancies__c;
  Latest_in_Precision_Medicine_and_Immuno__c= Latest_in_Precision_Medicine_and_Immuno__c;
  Highlights_of_ASH__c = Highlights_of_ASH__c;
  ASH_Quality_Improvement_and_Clinical_Pra__c = ASH_Quality_Improvement_and_Clinical_Pra__c;
  Medical_Students__c = Medical_Students__c;
  Career_and_Training__c = Career_and_Training__c;
  Honorific_and_Mentor__c = Honorific_and_Mentor__c;
  Webinars_Webcasts_Podcasts__c = Webinars_Webcasts_Podcasts__c;
  Job_Center_Opportunities__c = Job_Center_Opportunities__c;
  Global_Opportunities__c  = Global_Opportunities__c;
  Opportunities_for_Trainees__c = Opportunities_for_Trainees__c;
  Medical_education_and_recruitment__c= Medical_education_and_recruitment__c;
  Advance_Notice__c = Advance_Notice__c;
  Blood_Advances_Highlights__c = Blood_Advances_Highlights__c;
  This_Week_in_Blood__c = This_Week_in_Blood__c;
  ASH_Clinical_Trials__c = ASH_Clinical_Trials__c;
  TraineE_News__c = TraineE_News__c;
  ASH_Practice_Update__c = ASH_Practice_Update__c;
  ASH_Newslink__c = ASH_Newslink__c;
  Sickle_Cell_Disease__c = Sickle_Cell_Disease__c;
  The_Hematologist__c = The_Hematologist__c;
  ASH_News_Daily__c = ASH_News_Daily__c;
  HasOptedOutOfEmail = HasOptedOutOfEmail;
  Membership_Status__c = Membership_Status__c;
  ASH_Member__c = ASH_Member__c;
  On_Point_Blood_Neoplasia__c	 =  On_Point_Blood_Neoplasia__c;
  On_Point_Blood_VTH__c = On_Point_Blood_VTH__c;
  Email = this.Email;
  Email_Subscriptions_Last_Updated_Date__c = Email_Subscriptions_Last_Updated_Date__c;


  @track ASH_Annual_Meeting__c;

   @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID, ASH_MEMBER] })
  user;
  get membershipStatus(){
    let currentMembershipStatus = getFieldValue(this.user.data, ASH_MEMBER);

      if(currentMembershipStatus == true){
         return true;
  
       }
       else{
        return false;
       }
  
  }

  get contactId() {

    this.memberStatus = this.Membership_Status__c;
    return getFieldValue(this.user.data, CONTACT_ID);
   
  }

    handleClick(event){
   
     window.location.reload(); 
     this.checkbox23 = false;
     this.checkbox24 = false;

      
    }

    
  handleCheckAll(event){
    console.log('In the check All');
    console.log('Event ' +event.target.checked);

    this.checkbox24 = event.target.checked;
  
    if(this.checkbox24 == true){
  
    const ischecked = true;
    const isUnchecked = false;
    this.checkbox1 = ischecked;
    this.checkbox2 = ischecked;
    this.checkbox3 = ischecked;
    this.checkbox4 = ischecked;
    this.checkbox5 = ischecked;
    this.checkbox6 = ischecked;
    this.checkbox7 = ischecked;
    this.checkbox8 = ischecked;
    this.checkbox9 = ischecked;
    this.checkbox10 = ischecked;
    this.checkbox11 = ischecked;
    this.checkbox12 = ischecked;
    this.checkbox13 = ischecked;
    this.checkbox14 = ischecked;
    this.checkbox15 = ischecked;
    this.checkbox16 = ischecked;
    this.checkbox17 = ischecked;
    this.checkbox18 = ischecked;
    this.checkbox19 = ischecked;
    this.checkbox20 = ischecked;
    this.checkbox21 = ischecked;
    this.checkbox22 = ischecked;
    this.checkbox25 = ischecked;
    this.checkbox26 = ischecked;
    this.checkbox27 = ischecked;
    this.checkbox23 = isUnchecked;

    }
  }
  handleUnCheckAll(event){

    this.checkbox23 = event.target.checked;
   
  if(this.checkbox23 == true){
    const isUnchecked = false;
    this.checkbox1 = isUnchecked;
    this.checkbox2 = isUnchecked;
    this.checkbox3 = isUnchecked;
    this.checkbox4 = isUnchecked;
    this.checkbox5 = isUnchecked;
    this.checkbox6 = isUnchecked;
    this.checkbox7 = isUnchecked;
    this.checkbox8 = isUnchecked;
    this.checkbox9 = isUnchecked;
    this.checkbox10 = isUnchecked;
    this.checkbox11 = isUnchecked;
    this.checkbox12 = isUnchecked;
    this.checkbox13 = isUnchecked;
    this.checkbox14 = isUnchecked;
    this.checkbox15 = isUnchecked;
    this.checkbox16 = isUnchecked;
    this.checkbox17 = isUnchecked;
    this.checkbox18 = isUnchecked;
    this.checkbox19 = isUnchecked;
    this.checkbox20 = isUnchecked;
    this.checkbox21 = isUnchecked;
    this.checkbox22 = isUnchecked;
    this.checkbox25 = isUnchecked;
    this.checkbox26 = isUnchecked;
    this.checkbox27 = isUnchecked;
    this.checkbox24 = false;

  }
}

handleCheck1(event){
let checkEvent = event.target.value;
let itemId = event.target.dataset.id;

  if(checkEvent == true){
  
    if(itemId == 'ASH_Annual_Meeting__c'){
      this.checkbox1 = true;
    }

    
    this.checkbox23 = false;
    this.checkbox24 = false;
    }

    else{
    this.checkbox24 = false;

    if(itemId == 'ASH_Annual_Meeting__c'){
      this.checkbox1 = false;
    }
    
  }

}
handleCheck2(event){
  let checkEvent = event.target.value;
  let itemId = event.target.dataset.id;
    if(checkEvent == true){
      if(itemId == 'ASH_Meeting_on_Hematologic_Malignancies__c'){
        this.checkbox2 = true;
      }
      this.checkbox23 = false;
      this.checkbox24 = false;
      }
      else{
      this.checkbox24 = false;
      if(itemId == 'ASH_Meeting_on_Hematologic_Malignancies__c'){
        this.checkbox2 = false;
      }
    }
  } 
  handleCheck3(event){
    let checkEvent = event.target.value;
    let itemId = event.target.dataset.id;
      if(checkEvent == true){
        if(itemId == 'Latest_in_Precision_Medicine_and_Immuno__c'){
          this.checkbox3 = true;
        }
        this.checkbox23 = false;
        this.checkbox24 = false;
        }
        else{
        this.checkbox24 = false;
        if(itemId == 'Latest_in_Precision_Medicine_and_Immuno__c'){
          this.checkbox3 = false;
        }
      }
    } 
    handleCheck4(event){
      let checkEvent = event.target.value;
      let itemId = event.target.dataset.id;
        if(checkEvent == true){
          if(itemId == 'Highlights_of_ASH__c'){
            this.checkbox4 = true;
          }
          this.checkbox23 = false;
          this.checkbox24 = false;
          }
          else{
          this.checkbox24 = false;
          if(itemId == 'Highlights_of_ASH__c'){
            this.checkbox4 = false;
          }
        }
      } 

      handleCheck5(event){
        let checkEvent = event.target.value;
        let itemId = event.target.dataset.id;
          if(checkEvent == true){
            if(itemId == 'ASH_Quality_Improvement_and_Clinical_Pra__c'){
              this.checkbox5 = true;
            }
            this.checkbox23 = false;
            this.checkbox24 = false;
            }
            else{
            this.checkbox24 = false;
            if(itemId == 'ASH_Quality_Improvement_and_Clinical_Pra__c'){
              this.checkbox5 = false;
            }
          }
        } 

        handleCheck6(event){
          let checkEvent = event.target.value;
          let itemId = event.target.dataset.id;
            if(checkEvent == true){
              if(itemId == 'Medical_Students__c'){
                this.checkbox6 = true;
              }
              this.checkbox23 = false;
              this.checkbox24 = false;
              }
              else{
              this.checkbox24 = false;
              if(itemId == 'Medical_Students__c'){
                this.checkbox6 = false;
              }
            }
          } 

          handleCheck7(event){
            let checkEvent = event.target.value;
            let itemId = event.target.dataset.id;
              if(checkEvent == true){
                if(itemId == 'Career_and_Training__c'){
                  this.checkbox7 = true;
                }
                this.checkbox23 = false;
                this.checkbox24 = false;
                }
                else{
                this.checkbox24 = false;
                if(itemId == 'Career_and_Training__c'){
                  this.checkbox7 = false;
                }
              }
            } 

            handleCheck8(event){
              let checkEvent = event.target.value;
              let itemId = event.target.dataset.id;
                if(checkEvent == true){
                  if(itemId == 'Honorific_and_Mentor__c'){
                    this.checkbox8 = true;
                  }
                  this.checkbox23 = false;
                  this.checkbox24 = false;
                  }
                  else{
                  this.checkbox24 = false;
                  if(itemId == 'Honorific_and_Mentor__c'){
                    this.checkbox8 = false;
                  }
                }
              } 
              handleCheck9(event){
                let checkEvent = event.target.value;
                let itemId = event.target.dataset.id;
                  if(checkEvent == true){
                    if(itemId == 'Webinars_Webcasts_Podcasts__c'){
                      this.checkbox9 = true;
                    }
                    this.checkbox23 = false;
                    this.checkbox24 = false;
                    }
                    else{
                    this.checkbox24 = false;
                    if(itemId == 'Webinars_Webcasts_Podcasts__c'){
                      this.checkbox9 = false;
                    }
                  }
                } 

                handleCheck10(event){
                  let checkEvent = event.target.value;
                  let itemId = event.target.dataset.id;
                    if(checkEvent == true){
                      if(itemId == 'Job_Center_Opportunities__c'){
                        this.checkbox10 = true;
                      }
                      this.checkbox23 = false;
                      this.checkbox24 = false;
                      }
                      else{
                      this.checkbox24 = false;
                      if(itemId == 'Job_Center_Opportunities__c'){
                        this.checkbox10 = false;
                      }
                    }
                  } 
  
                  handleCheck11(event){
                    let checkEvent = event.target.value;
                    let itemId = event.target.dataset.id;
                      if(checkEvent == true){
                        if(itemId == 'Global_Opportunities__c'){
                          this.checkbox11 = true;
                        }
                        this.checkbox23 = false;
                        this.checkbox24 = false;
                        }
                        else{
                        this.checkbox24 = false;
                        if(itemId == 'Global_Opportunities__c'){
                          this.checkbox11 = false;
                        }
                      }
                    } 
                    handleCheck12(event){
                      let checkEvent = event.target.value;
                      let itemId = event.target.dataset.id;
                        if(checkEvent == true){
                          if(itemId == 'Opportunities_for_Trainees__c'){
                            this.checkbox12 = true;
                          }
                          this.checkbox23 = false;
                          this.checkbox24 = false;
                          }
                          else{
                          this.checkbox24 = false;
                          if(itemId == 'Opportunities_for_Trainees__c'){
                            this.checkbox12 = false;
                          }
                        }
                      } 
                      handleCheck13(event){
                        let checkEvent = event.target.value;
                        let itemId = event.target.dataset.id;
                          if(checkEvent == true){
                            if(itemId == 'Medical_Education_and_Recruitment__c'){
                              this.checkbox13 = true;
                            }
                            this.checkbox23 = false;
                            this.checkbox24 = false;
                            }
                            else{
                            this.checkbox24 = false;
                            if(itemId == 'Medical_Education_and_Recruitment__c'){
                              this.checkbox13 = false;
                            }
                          }
                        }    
                        handleCheck14(event){
                          let checkEvent = event.target.value;
                          let itemId = event.target.dataset.id;
                            if(checkEvent == true){
                              if(itemId == 'Advance_Notice__c'){
                                this.checkbox14 = true;
                              }
                              this.checkbox23 = false;
                              this.checkbox24 = false;
                              }
                              else{
                              this.checkbox24 = false;
                              if(itemId == 'Advance_Notice__c'){
                                this.checkbox14 = false;
                              }
                            }
                          }    
                          handleCheck15(event){
                            let checkEvent = event.target.value;
                            let itemId = event.target.dataset.id;
                              if(checkEvent == true){
                                if(itemId == 'Blood_Advances_Highlights__c'){
                                  this.checkbox15 = true;
                                }
                                this.checkbox23 = false;
                                this.checkbox24 = false;
                                }
                                else{
                                this.checkbox24 = false;
                                if(itemId == 'Blood_Advances_Highlights__c'){
                                  this.checkbox15 = false;
                                }
                              }
                            }    
                            handleCheck16(event){
                              let checkEvent = event.target.value;
                              let itemId = event.target.dataset.id;
                                if(checkEvent == true){
                                  if(itemId == 'This_Week_in_Blood__c'){
                                    this.checkbox16 = true;
                                  }
                                  this.checkbox23 = false;
                                  this.checkbox24 = false;
                                  }
                                  else{
                                  this.checkbox24 = false;
                                  if(itemId == 'This_Week_in_Blood__c'){
                                    this.checkbox16 = false;
                                  }
                                }
                              }    
                              handleCheck17(event){
                                let checkEvent = event.target.value;
                                let itemId = event.target.dataset.id;
                                  if(checkEvent == true){
                                    if(itemId == 'ASH_Clinical_Trials__c'){
                                      this.checkbox17 = true;
                                    }
                                    this.checkbox23 = false;
                                    this.checkbox24 = false;
                                    }
                                    else{
                                    this.checkbox24 = false;
                                    if(itemId == 'ASH_Clinical_Trials__c'){
                                      this.checkbox17 = false;
                                    }
                                  }
                                }                      
                                handleCheck18(event){
                                  let checkEvent = event.target.value;
                                  let itemId = event.target.dataset.id;
                                    if(checkEvent == true){
                                      if(itemId == 'ASH_Practice_Update__c'){
                                        this.checkbox18 = true;
                                      }
                                      this.checkbox23 = false;
                                      this.checkbox24 = false;
                                      }
                                      else{
                                      this.checkbox24 = false;
                                      if(itemId == 'ASH_Practice_Update__c'){
                                        this.checkbox18 = false;
                                      }
                                    }
                                  }        
                                  handleCheck19(event){
                                    let checkEvent = event.target.value;
                                    let itemId = event.target.dataset.id;
                                      if(checkEvent == true){
                                        if(itemId == 'Sickle_Cell_Disease__c'){
                                          this.checkbox19 = true;
                                        }
                                        this.checkbox23 = false;
                                        this.checkbox24 = false;
                                        }
                                        else{
                                        this.checkbox24 = false;
                                        if(itemId == 'Sickle_Cell_Disease__c'){
                                          this.checkbox19 = false;
                                        }
                                      }
                                    }        
                                    handleCheck20(event){
                                      let checkEvent = event.target.value;
                                      let itemId = event.target.dataset.id;
                                        if(checkEvent == true){
                                          if(itemId == 'ASH_Newslink__c'){
                                            this.checkbox20 = true;
                                          }
                                          this.checkbox23 = false;
                                          this.checkbox24 = false;
                                          }
                                          else{
                                          this.checkbox24 = false;
                                          if(itemId == 'ASH_Newslink__c'){
                                            this.checkbox20 = false;
                                          }
                                        }
                                      }        
                                      handleCheck21(event){
                                        let checkEvent = event.target.value;
                                        let itemId = event.target.dataset.id;
                                          if(checkEvent == true){
                                            if(itemId == 'The_Hematologist__c'){
                                              this.checkbox21 = true;
                                            }
                                            this.checkbox23 = false;
                                            this.checkbox24 = false;
                                            }
                                            else{
                                            this.checkbox24 = false;
                                            if(itemId == 'The_Hematologist__c'){
                                              this.checkbox21 = false;
                                            }
                                          }
                                        }                 
                                        handleCheck22(event){
                                          let checkEvent = event.target.value;
                                          let itemId = event.target.dataset.id;
                                            if(checkEvent == true){
                                              if(itemId == 'ASH_News_Daily__c'){
                                                this.checkbox22 = true;
                                              }
                                              this.checkbox23 = false;
                                              this.checkbox24 = false;
                                              }
                                              else{
                                              this.checkbox24 = false;
                                              if(itemId == 'ASH_News_Daily__c'){
                                                this.checkbox22 = false;
                                              }
                                            }
                                          }                 
                                          handleCheck25(event){
                                            let checkEvent = event.target.value;
                                            let itemId = event.target.dataset.id;
                                            
                                              if(checkEvent == true){
                                              
                                                if(itemId == 'TraineE_News__c'){
                                                  this.checkbox25 = true;
                                                }
                                            
                                                
                                                this.checkbox23 = false;
                                                this.checkbox24 = false;
                                                }
                                            
                                                else{
                                                this.checkbox24 = false;
                                            
                                                if(itemId == 'TraineE_News__c'){
                                                  this.checkbox25 = false;
                                                }
                                                
                                              }
                                            
                                            }
                                            handleCheck26(event){
                                              let checkEvent = event.target.value;
                                              let itemId = event.target.dataset.id;
                                              
                                                if(checkEvent == true){
                                                
                                                  if(itemId == 'On_Point_Blood_Neoplasia__c'){
                                                    this.checkbox26 = true;
                                                  }
                                              
                                                  
                                                  this.checkbox23 = false;
                                                  this.checkbox24 = false;
                                                  }
                                              
                                                  else{
                                                  this.checkbox24 = false;
                                              
                                                  if(itemId == 'On_Point_Blood_Neoplasia__c'){
                                                    this.checkbox26 = false;
                                                  }
                                                  
                                                }
                                              
                                              }
                                              handleCheck27(event){
                                                let checkEvent = event.target.value;
                                                let itemId = event.target.dataset.id;
                                                
                                                  if(checkEvent == true){
                                                  
                                                    if(itemId == 'On_Point_Blood_VTH__c'){
                                                      this.checkbox27 = true;
                                                    }
                                                
                                                    
                                                    this.checkbox23 = false;
                                                    this.checkbox24 = false;
                                                    }
                                                
                                                    else{
                                                    this.checkbox24 = false;
                                                
                                                    if(itemId == 'On_Point_Blood_VTH__c'){
                                                      this.checkbox27 = false;
                                                    }
                                                    
                                                  }
                                                
                                                }

                                          }