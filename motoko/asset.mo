import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Iter "mo:base/Iter";


actor Asset {
    type Inventory = {
        name: Text;
        nbOfChest : Nat;
        laserPotions : Nat;
        angelPotions : Nat;
        laserBirds : [Nat];
        angelBirds : [Nat];
    };

    type ChestResult = {
        laserPotion : Bool;
        angelPotion : Bool;
        coins : Nat;
    };

    type ChestReceipt = {
        #Ok: ChestResult;
        #Err : {
            #NotEnoughChest;
            #UserNotFoud;
            #EntropyError;
        };
    };

    type InventoryResult = {
        #Ok : Inventory;
        #Err : {
            #NewUserCreated;
        };
    };

    type BuyChestReceipt = {
        #Ok;
        #Err: {
            #UserNotFoud;
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other: Text;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    public type TxReceipt = {
        #Ok: Nat;
        #Err: {
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other: Text;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    // Function left : setName, useLaserPotion, useAngelPotion, 

    private var chest_price : Nat = 1_000;
    private var rename_price : Nat = 100;
    private var tokenCanisterId : Text = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    private var owner : Principal = Principal.fromText("7ly2x-6aagz-er6jy-ae42u-soscs-sij57-q25r2-gn5f3-nibrt-cid53-fqe");
    private var inventories = HashMap.HashMap<Principal, Inventory>(1, Principal.equal, Principal.hash);
    private stable var inventoriesEntries : [(Principal, Text, Nat, Nat, Nat, [Nat], [Nat])] = [];

    public shared(msg) func setTokenCanisterId(newID: Text) {
        assert(msg.caller == owner);
        tokenCanisterId := newID;
    };

    public shared(msg) func setOwner(p : Principal) {
        assert(msg.caller == p);
        owner := p;
    };

    public shared(msg) func setNewName(newName : Text) : async (BuyChestReceipt) {
        let user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                let tocallcanister = actor(tokenCanisterId): actor {
                    transfer : shared (to: Principal, value: Nat) -> async (TxReceipt);
                    approve : shared (spender: Principal, value: Nat) -> async (TxReceipt);
                    transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async (TxReceipt);
                };
                // let from = Principal.fromText("7ly2x-6aagz-er6jy-ae42u-soscs-sij57-q25r2-gn5f3-nibrt-cid53-fqe");
                // let to = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
                let to = Principal.fromActor(Asset);
                let res = await tocallcanister.transferFrom(msg.caller, to, rename_price);
                switch(res) {
                    case(#Ok(val)) {
                        let newUserData : Inventory = {
                            name = newName;
                            nbOfChest = u.nbOfChest;
                            laserPotions = u.laserPotions;
                            angelPotions = u.angelPotions;
                            laserBirds = u.laserBirds;
                            angelBirds = u.angelBirds;
                        };
                        inventories.put(msg.caller, newUserData);
                        return #Ok;
                    };
                    case(#Err(e)) {
                        return #Err(e);
                    };
                };
            };
            case(_) {
                let newUserData : Inventory = {
                    name = Principal.toText(msg.caller);
                    nbOfChest = 0;
                    laserPotions = 0;
                    angelPotions = 0;
                    laserBirds = [];
                    angelBirds = [];
                };
                inventories.put(msg.caller, newUserData);
                return #Err(#UserNotFoud);
            };
        };

    };

    public shared(msg) func getUserInventory() : async (Inventory) {
        let user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                return u;
            };
            case(_) {
                let newUserData : Inventory = {
                    name = Principal.toText(msg.caller);
                    nbOfChest = 0;
                    laserPotions = 0;
                    angelPotions = 0;
                    laserBirds = [];
                    angelBirds = [];
                };
                inventories.put(msg.caller, newUserData);
                return newUserData;
            };
        };
    };

    public shared(msg) func openChest() : async (ChestReceipt) {
        var user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                if(u.nbOfChest < 1) {
                    return #Err(#NotEnoughChest);
                };
                let max : Nat8 = 8;
                var entropy : Blob = await Random.blob();
                var f = Random.Finite(entropy);
                let v = f.range(max);
                switch(v) {
                    case(?vals) {
                        var angelResult = false;
                        var laserResult = false;
                        if(vals < 13) {
                            angelResult := true;
                        } else if (vals > 242) {
                            laserResult := true;
                        };
                        let res : ChestResult = {
                            laserPotion = laserResult;
                            angelPotion = angelResult;
                            coins = vals;
                        };
                        var newLaserPotionsCount = u.laserPotions;
                        var newAngelPotionsCount = u.angelPotions;
                        if(laserResult) {
                            newLaserPotionsCount += 1;
                        };
                        if(angelResult) {
                            newAngelPotionsCount += 1;
                        };
                        let newUserData : Inventory = {
                            name = u.name;
                            nbOfChest = u.nbOfChest - 1;
                            laserPotions = newLaserPotionsCount;
                            angelPotions = newAngelPotionsCount;
                            laserBirds = u.laserBirds;
                            angelBirds = u.angelBirds;
                        };
                        inventories.put(msg.caller, newUserData);
                        return #Ok(res);
                    };
                    case(_) {
                        entropy := await Random.blob(); // get initial entropy
                        return #Err(#EntropyError);
                    };
                };
            };
            case(_) {
                let newUserData : Inventory = {
                    name = Principal.toText(msg.caller);
                    nbOfChest = 0;
                    laserPotions = 0;
                    angelPotions = 0;
                    laserBirds = [];
                    angelBirds = [];
                };
                inventories.put(msg.caller, newUserData);
                return #Err(#UserNotFoud);
            };
        };
    };

    public shared(msg) func buyChest() : async (BuyChestReceipt) {
        var user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                let tocallcanister = actor(tokenCanisterId): actor {
                    transfer : shared (to: Principal, value: Nat) -> async (TxReceipt);
                    approve : shared (spender: Principal, value: Nat) -> async (TxReceipt);
                    transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async (TxReceipt);
                };
                // let from = Principal.fromText("7ly2x-6aagz-er6jy-ae42u-soscs-sij57-q25r2-gn5f3-nibrt-cid53-fqe");
                // let to = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai");
                let to = Principal.fromActor(Asset);
                let res = await tocallcanister.transferFrom(msg.caller, to, chest_price);
                switch(res) {
                    case(#Ok(val)) {
                        let newUserData : Inventory = {
                            name = u.name;
                            nbOfChest = u.nbOfChest + 1;
                            laserPotions = u.laserPotions;
                            angelPotions = u.angelPotions;
                            laserBirds = u.laserBirds;
                            angelBirds = u.angelBirds;
                        };
                        inventories.put(msg.caller, newUserData);
                        return #Ok;
                    };
                    case(#Err(e)) {
                        return #Err(e);
                    };
                };
            };
            case(_) {
                let newUserData : Inventory = {
                    name = Principal.toText(msg.caller);
                    nbOfChest = 0;
                    laserPotions = 0;
                    angelPotions = 0;
                    laserBirds = [];
                    angelBirds = [];
                };
                inventories.put(msg.caller, newUserData);
                return #Err(#UserNotFoud);
            };
        };
    };

        /*
    * upgrade functions
    */
    system func preupgrade() {
        var size : Nat = inventories.size();
        var temp : [var (Principal, Text, Nat, Nat, Nat, [Nat], [Nat])] = Array.init<(Principal, Text, Nat, Nat, Nat, [Nat], [Nat])>(size, (owner, "", 0, 0, 0, [], []));
        size := 0;
        for ((k, v) in inventories.entries()) {
            let element : (Principal, Text, Nat, Nat, Nat, [Nat], [Nat]) = (k, v.name, v.nbOfChest, v.laserPotions, v.angelPotions, v.laserBirds, v.angelBirds);
            temp[size] := element;
            size += 1;
        };
        inventoriesEntries := Array.freeze(temp);
    };

    system func postupgrade() {
        for ((a,b,c,d,e,f,g) in inventoriesEntries.vals()) {
            let allowed_temp : Inventory = {
                name = b;
                nbOfChest = c;
                laserPotions = d;
                angelPotions = e;
                laserBirds = f;
                angelBirds = g;
            };
            inventories.put(a, allowed_temp);
        };
        inventoriesEntries := [];
    };
} 

// rrkah-fqaaa-aaaaa-aaaaq-cai