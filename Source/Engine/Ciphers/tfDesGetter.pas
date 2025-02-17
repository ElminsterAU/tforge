{
                       TForge Library
        Copyright (c) Sergey Kasandrov 1997, 2018

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-------------------------------------------------------------------------

  # exports:
      ValidDesAlgID, GetDesInstance
}

unit tfDesGetter;

{$I TFL.inc}

interface

uses
  tfTypes, tfCipherInstances, tfBlockCiphers, tfDesCiphers;

function ValidDesAlgID(AlgID: TAlgID): Boolean;
function GetDesInstance(var A: Pointer; AlgID: TAlgID): TF_RESULT;

implementation

uses
  tfRecords, tfHelpers, tfCipherHelpers;

const
  DesEcbVTable: TCipherHelper.TVTable = (
    @TForgeInstance.QueryIntf,
    @TForgeInstance.Addref,
    @TForgeInstance.SafeRelease,

    @TDesInstance.Burn,
    @TDesInstance.Clone,
    @TDesInstance.ExpandKey,
    @TCipherInstance.ExpandKeyIV,
    @TCipherInstance.ExpandKeyNonce,
    @TCipherInstance.GetBlockSize64,
    @TBlockCipherInstance.EncryptUpdateECB,
    @TBlockCipherInstance.DecryptUpdateECB,
    @TDesInstance.EncryptBlock,
    @TDesInstance.EncryptBlock,
    @TCipherInstance.BlockMethodStub,
    @TCipherInstance.DataMethodStub,
    @TBlockCipherInstance.EncryptECB,
    @TBlockCipherInstance.DecryptECB,
    @TCipherInstance.IsBlockCipher,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TBlockCipherInstance.SetIV,
    @TBlockCipherInstance.SetNonce,
    @TBlockCipherInstance.GetIV,
    @TBlockCipherInstance.GetNonce,
    @TBlockCipherInstance.GetIVPointer,
    @TCipherInstance.SetKeyDir,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub
  );

  DesCbcVTable: TCipherHelper.TVTable = (
    @TForgeInstance.QueryIntf,
    @TForgeInstance.Addref,
    @TForgeInstance.SafeRelease,

    @TDesInstance.Burn,
    @TDesInstance.Clone,
    @TDesInstance.ExpandKey,
    @TCipherInstance.ExpandKeyIV,
    @TCipherInstance.ExpandKeyNonce,
    @TCipherInstance.GetBlockSize64,
    @TBlockCipherInstance.EncryptUpdateCBC,
    @TBlockCipherInstance.DecryptUpdateCBC,
    @TDesInstance.EncryptBlock,
    @TDesInstance.EncryptBlock,
    @TCipherInstance.BlockMethodStub,
    @TCipherInstance.DataMethodStub,
    @TBlockCipherInstance.EncryptCBC,
    @TBlockCipherInstance.DecryptCBC,
    @TCipherInstance.IsBlockCipher,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TBlockCipherInstance.SetIV,
    @TBlockCipherInstance.SetNonce,
    @TBlockCipherInstance.GetIV,
    @TBlockCipherInstance.GetNonce,
    @TBlockCipherInstance.GetIVPointer,
    @TCipherInstance.SetKeyDir,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub
  );

  DesCfbVTable: TCipherHelper.TVTable = (
    @TForgeInstance.QueryIntf,
    @TForgeInstance.Addref,
    @TForgeInstance.SafeRelease,

    @TDesInstance.Burn,
    @TDesInstance.Clone,
    @TDesInstance.ExpandKey,
    @TCipherInstance.ExpandKeyIV,
    @TCipherInstance.ExpandKeyNonce,
    @TCipherInstance.GetBlockSize64,
    @TBlockCipherInstance.EncryptUpdateCFB,
    @TBlockCipherInstance.DecryptUpdateCFB,
    @TDesInstance.EncryptBlock,
    @TDesInstance.EncryptBlock,
    @TCipherInstance.BlockMethodStub,
    @TCipherInstance.DataMethodStub,
    @TBlockCipherInstance.EncryptCFB,
    @TBlockCipherInstance.DecryptCFB,
    @TCipherInstance.IsBlockCipher,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TBlockCipherInstance.SetIV,
    @TBlockCipherInstance.SetNonce,
    @TBlockCipherInstance.GetIV,
    @TBlockCipherInstance.GetNonce,
    @TBlockCipherInstance.GetIVPointer,
    @TCipherInstance.SetKeyDir,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub
  );

  DesOfbVTable: TCipherHelper.TVTable = (
    @TForgeInstance.QueryIntf,
    @TForgeInstance.Addref,
    @TForgeInstance.SafeRelease,

    @TDesInstance.Burn,
    @TDesInstance.Clone,
    @TDesInstance.ExpandKey,
    @TCipherInstance.ExpandKeyIV,
    @TCipherInstance.ExpandKeyNonce,
    @TCipherInstance.GetBlockSize64,
    @TBlockCipherInstance.EncryptUpdateOFB,
    @TBlockCipherInstance.EncryptUpdateOFB,
    @TDesInstance.EncryptBlock,
    @TDesInstance.EncryptBlock,
    @TCipherInstance.BlockMethodStub,
    @TCipherInstance.DataMethodStub,
    @TBlockCipherInstance.EncryptOFB,
    @TBlockCipherInstance.EncryptOFB,
    @TCipherInstance.IsBlockCipher,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TCipherInstance.IncBlockNoStub,
    @TBlockCipherInstance.SetIV,
    @TBlockCipherInstance.SetNonce,
    @TBlockCipherInstance.GetIV,
    @TBlockCipherInstance.GetNonce,
    @TBlockCipherInstance.GetIVPointer,
    @TCipherInstance.SetKeyDir,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub
  );

  DesCtrVTable: TCipherHelper.TVTable = (
    @TForgeInstance.QueryIntf,
    @TForgeInstance.Addref,
    @TForgeInstance.SafeRelease,

    @TDesInstance.Burn,
    @TDesInstance.Clone,
    @TDesInstance.ExpandKey,
    @TCipherInstance.ExpandKeyIV,
    @TCipherInstance.ExpandKeyNonce,
    @TCipherInstance.GetBlockSize64,
    @TBlockCipherInstance.EncryptUpdateCTR,
    @TBlockCipherInstance.EncryptUpdateCTR,
    @TDesInstance.EncryptBlock,
    @TDesInstance.EncryptBlock,
    @TBlockCipherInstance.GetKeyBlockCTR,
    @TBlockCipherInstance.GetKeyStreamCTR,
    @TBlockCipherInstance.EncryptCTR,
    @TBlockCipherInstance.EncryptCTR,
    @TCipherInstance.IsBlockCipher,
    @TBlockCipherInstance.IncBlockNoCTR,
    @TBlockCipherInstance.DecBlockNoCTR,
    @TBlockCipherInstance.SkipCTR,
    @TBlockCipherInstance.SetIV,
    @TBlockCipherInstance.SetNonce,
    @TBlockCipherInstance.GetIV,
    @TBlockCipherInstance.GetNonce,
    @TBlockCipherInstance.GetIVPointer,
    @TCipherInstance.SetKeyDir,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub,
    @TCipherInstance.DataMethodStub
  );

function ValidDesAlgID(AlgID: TAlgID): Boolean;
begin
  Result:= False;
  case AlgID and TF_KEYMODE_MASK of
    TF_KEYMODE_ECB,
    TF_KEYMODE_CBC:
      case AlgID and TF_PADDING_MASK of
        TF_PADDING_DEFAULT,
        TF_PADDING_NONE,
        TF_PADDING_ZERO,
        TF_PADDING_ANSI,
        TF_PADDING_PKCS,
        TF_PADDING_ISO: Result:= True;
      end;
    TF_KEYMODE_CFB,
    TF_KEYMODE_OFB,
    TF_KEYMODE_CTR:
      case AlgID and TF_PADDING_MASK of
        TF_PADDING_DEFAULT,
        TF_PADDING_NONE: Result:= True;
      end;
  end;
end;

function GetVTable(AlgID: TAlgID): Pointer;
begin
  case AlgID and TF_KEYMODE_MASK of
    TF_KEYMODE_ECB: Result:= @DesEcbVTable;
    TF_KEYMODE_CBC: Result:= @DesCbcVTable;
    TF_KEYMODE_CFB: Result:= @DesCfbVTable;
    TF_KEYMODE_OFB: Result:= @DesOfbVTable;
    TF_KEYMODE_CTR: Result:= @DesCtrVTable;
  else
    Result:= nil;
  end;
end;

function GetDesInstance(var A: Pointer; AlgID: TAlgID): TF_RESULT;
var
  Tmp: PCipherInstance;
  LVTable: Pointer;

begin
  if not ValidDesAlgID(AlgID) then begin
    Result:= TF_E_INVALIDARG;
    Exit;
  end;

  LVTable:= GetVTable(AlgID);

  try
    Tmp:= AllocMem(SizeOf(TDesInstance));
    Tmp.FVTable:= LVTable;
    Tmp.FRefCount:= 1;
    Tmp.FAlgID:= AlgID;

    TForgeHelper.Free(A);
    A:= Tmp;
    Result:= TF_S_OK;
  except
    Result:= TF_E_OUTOFMEMORY;
  end;
end;

end.
