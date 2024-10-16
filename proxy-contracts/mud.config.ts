import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  namespace: "core",
  tables: {
    InputBoxAddress: {
      schema: {
        value: "address",
      },
      key: [],
    },
    DappAddressNamespace: {
      schema: {
        namespace: "bytes32", 
        dappAddress: "address",
      },
      key: ["dappAddress"],
    },
    NamespaceDappAddress: {
      schema: {
        namespace: "bytes32", 
        dappAddress: "address",
      },
      key: ["namespace"],
    },
    CartridgeAssetAddress: {
      schema: {
        value: "address",
      },
      key: [],
    },
    CartridgeOwner: {
      schema: {
        cartridgeId: "bytes32", 
        owner: "address",
      },
      key: ["cartridgeId"],
    },
    TapeAssetAddress: {
      schema: {
        value: "address",
      },
      key: [],
    },
    TapeCreator: {
      schema: {
        tapeId: "bytes32", 
        owner: "address",
      },
      key: ["tapeId"],
    },
    RegisteredModel: {
      schema: {
        modelAddress: "address", 
        active: "bool",
      },
      key: ["modelAddress"],
    },
    CartridgeInsertionModel: {
      schema: {
        modelAddress: "address",
        config: "bytes"
      },
      key: [],
    },
    TapeSubmissionModel: {
      schema: {
        cartridgeId: "bytes32", 
        modelAddress: "address",
        config: "bytes"
      },
      key: ["cartridgeId"],
    },
  },
  systems: {
    AdminSystem: {
      openAccess: false,
    },
    InputSystem: {
      openAccess: false,
      deploy:{
        registerWorldFunctions:false
      }
    },
    InputBoxSystem: {
      openAccess: false,
      deploy:{
        registerWorldFunctions:false
      }
    },
  },
});
