// By ficool2
::GetPropArraySize <- ::NetProps.GetPropArraySize.bindenv(::NetProps);
::GetPropEntity <- ::NetProps.GetPropEntity.bindenv(::NetProps);
::GetPropEntityArray <- ::NetProps.GetPropEntityArray.bindenv(::NetProps);
::GetPropFloat <- ::NetProps.GetPropFloat.bindenv(::NetProps);
::GetPropFloatArray <- ::NetProps.GetPropFloatArray.bindenv(::NetProps);
::GetPropInt <- ::NetProps.GetPropInt.bindenv(::NetProps);
::GetPropIntArray <- ::NetProps.GetPropIntArray.bindenv(::NetProps);
::GetPropString <- ::NetProps.GetPropString.bindenv(::NetProps);
::GetPropStringArray <- ::NetProps.GetPropStringArray.bindenv(::NetProps);
::GetPropType <- ::NetProps.GetPropType.bindenv(::NetProps);
::GetPropVector <- ::NetProps.GetPropVector.bindenv(::NetProps);
::GetPropVectorArray <- ::NetProps.GetPropVectorArray.bindenv(::NetProps);
::HasProp <- ::NetProps.HasProp.bindenv(::NetProps);
::SetPropEntity <- ::NetProps.SetPropEntity.bindenv(::NetProps);
::SetPropEntityArray <- ::NetProps.SetPropEntityArray.bindenv(::NetProps);
::SetPropFloat <- ::NetProps.SetPropFloat.bindenv(::NetProps);
::SetPropFloatArray <- ::NetProps.SetPropFloatArray.bindenv(::NetProps);
::SetPropInt <- ::NetProps.SetPropInt.bindenv(::NetProps);
::SetPropIntArray <- ::NetProps.SetPropIntArray.bindenv(::NetProps);
::SetPropString <- ::NetProps.SetPropString.bindenv(::NetProps);
::SetPropStringArray <- ::NetProps.SetPropStringArray.bindenv(::NetProps);
::SetPropVector <- ::NetProps.SetPropVector.bindenv(::NetProps);
::SetPropVectorArray <- ::NetProps.SetPropVectorArray.bindenv(::NetProps);

//testing
//these are less for performance reasons and moreso syntax
::SetValue <- ::Convars.SetValue.bindenv(::Convars);
::GetFloat <- ::Convars.GetFloat.bindenv(::Convars);

::RemoveOutput <- ::EntityOutputs.RemoveOutput.bindenv(::EntityOutputs);
::AddOutput <- ::EntityOutputs.AddOutput.bindenv(::EntityOutputs);

::FindByClassname <- ::Entities.FindByClassname.bindenv(::Entities);


//don't exist in l4d2
// ::GetPropBool <- ::NetProps.GetPropBool.bindenv(::NetProps);
// ::GetPropBoolArray <- ::NetProps.GetPropBoolArray.bindenv(::NetProps);
// ::GetPropInfo <- ::NetProps.GetPropInfo.bindenv(::NetProps);
// ::GetTable <- ::NetProps.GetTable.bindenv(::NetProps);
// ::SetPropBool <- ::NetProps.SetPropBool.bindenv(::NetProps);
// ::SetPropBoolArray <- ::NetProps.SetPropBoolArray.bindenv(::NetProps);
// ::GetInt <- ::Convars.GetInt.bindenv(::Convars);