unit TD32ToPDBResources;

interface

resourcestring
  RsNoTD32Info = 'File [%s] has no TD32 debug information!';
  RsListFieldCbInvalidLeaf = 'Unknown list leaf $%.4x passed to ListFieldCb()';
  RsGetTypeDependenciesInvLeaf = 'Invalid leaf $%.4x passed to GetTypeDependencies()';
  RsListFieldDepInvalidLeaf = 'Invalid leaf $%.4x passed to ListFieldDependency()';
  RsTranslateTypesInvLeaf = 'Invalid leaf $%.4x passed to TranslateTypes()';
  RsTranslateTypesInListFieldInvLeaf = 'Invalid leaf $%.4x passed to TranslateTypesInListField()';
  RsInvalidDSetSize = 'Invalid set size $%.4x found in type leaf of type TDS_LF_DSET';

implementation

end.
