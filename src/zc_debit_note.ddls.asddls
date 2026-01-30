@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Debit Note Adobe Form'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define root view entity ZC_DEBIT_NOTE
  provider contract transactional_query
  as projection on ZI_DEBIT_NOTE
{

      @EndUserText.label: 'Company Code'
  key BUKRS,
      @EndUserText.label: 'Fiscal Year'
  key GJAHR,
      @EndUserText.label: 'Document No'
  key BELNR,
      @EndUserText.label: 'base64'
      base64
}
