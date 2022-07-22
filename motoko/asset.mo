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
        expPotions: Nat;
        userLevel: Nat;
        laserBirds : [Nat];
        angelBirds : [Nat];
    };

    type ChestResult = {
        laserPotion : Bool;
        angelPotion : Bool;
        expPotion: Nat;
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

    type UsePotionResult = {
        #Ok;
        #Err: {
            #UserNotFoud;
            #NotEnoughPotion;
            #LevelMaxReached;
        };
    };

    // Function left : useLaserPotion, useAngelPotion, 

    private var chest_price : Nat = 1_000;
    private var rename_price : Nat = 100;
    private var levelUp : [Nat] = [1, 2, 4, 6, 8, 10];
    private var tokenCanisterId : Text = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    private var owner : Principal = Principal.fromText("7ly2x-6aagz-er6jy-ae42u-soscs-sij57-q25r2-gn5f3-nibrt-cid53-fqe");
    private var inventories = HashMap.HashMap<Principal, Inventory>(1, Principal.equal, Principal.hash);
    private stable var inventoriesEntries : [(Principal, Text, Nat, Nat, Nat, Nat, Nat, [Nat], [Nat])] = [];

    public shared(msg) func setTokenCanisterId(newID: Text) {
        assert(msg.caller == owner);
        tokenCanisterId := newID;
    };

    public shared(msg) func setOwner(p : Principal) {
        assert(msg.caller == owner);
        owner := p;
    };

    public shared(msg) func setChestPrice(newChestPrice: Nat) {
        assert(msg.caller == owner);
        chest_price := newChestPrice;
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
                            expPotions = u.expPotions;
                            userLevel = u.userLevel;
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
                    expPotions = 0;
                    userLevel = 0;
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
                    expPotions = 0;
                    userLevel = 0;
                    laserBirds = [];
                    angelBirds = [];
                };
                inventories.put(msg.caller, newUserData);
                return newUserData;
            };
        };
    };

    public shared(msg) func useLaserPotion(targetBird : Nat) : async (UsePotionResult) {
        var user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                if(u.laserPotions > 0) {
                    let newUserData : Inventory = {
                        name = u.name;
                        nbOfChest = u.nbOfChest;
                        laserPotions = u.laserPotions - 1;
                        angelPotions = u.angelPotions;
                        expPotions = u.expPotions;
                        userLevel = u.userLevel;
                        laserBirds = Array.append(u.laserBirds, [targetBird]);
                        angelBirds = u.angelBirds;
                    };
                    inventories.put(msg.caller, newUserData);
                    return #Ok;
                };
                return #Err(#NotEnoughPotion);
            };
            case(_) {
                return #Err(#UserNotFoud);
            };
        };
    };


    public shared(msg) func useAngelPotion(targetBird : Nat) : async (UsePotionResult) {
        var user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                if(u.angelPotions > 0) {
                    let newUserData : Inventory = {
                        name = u.name;
                        nbOfChest = u.nbOfChest;
                        laserPotions = u.laserPotions;
                        angelPotions = u.angelPotions - 1;
                        expPotions = u.expPotions;
                        userLevel = u.userLevel;
                        laserBirds = u.laserBirds;
                        angelBirds = Array.append(u.angelBirds, [targetBird]);
                    };
                    inventories.put(msg.caller, newUserData);
                    return #Ok;
                };
                return #Err(#NotEnoughPotion);
            };
            case(_) {
                return #Err(#UserNotFoud);
            };
        };
    };

    public shared(msg) func useExpPotion() : async (UsePotionResult) {
        var user = inventories.get(msg.caller);
        switch(user) {
            case(?u) {
                if(u.userLevel == 6) {
                    return #Err(#LevelMaxReached);
                };
                let requiredPotion = levelUp[u.userLevel];
                if(u.expPotions >= requiredPotion) {
                    let newUserData : Inventory = {
                        name = u.name;
                        nbOfChest = u.nbOfChest;
                        laserPotions = u.laserPotions;
                        angelPotions = u.angelPotions;
                        expPotions = u.expPotions - requiredPotion;
                        userLevel = u.userLevel + 1;
                        laserBirds = u.laserBirds;
                        angelBirds = u.angelBirds;
                    };
                    inventories.put(msg.caller, newUserData);
                    return #Ok;
                };
                return #Err(#NotEnoughPotion);
            };
            case(_) {
                return #Err(#UserNotFoud);
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
                        var newExpPotionsCount = 1;
                        if(vals < 13) {
                            angelResult := true;
                            newExpPotionsCount := newExpPotionsCount+1;
                        } else if (vals > 242) {
                            laserResult := true;
                            newExpPotionsCount := newExpPotionsCount+1;
                        };
                        if(vals < 125) {
                            newExpPotionsCount := newExpPotionsCount+1;
                        };
                        let res : ChestResult = {
                            laserPotion = laserResult;
                            angelPotion = angelResult;
                            expPotion = newExpPotionsCount;
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
                            expPotions = u.expPotions + newExpPotionsCount;
                            userLevel = u.userLevel;
                            laserBirds = u.laserBirds;
                            angelBirds = u.angelBirds;
                        };
                        inventories.put(msg.caller, newUserData);
                        let tocallcanister = actor(tokenCanisterId): actor {
                            transfer : shared (to: Principal, value: Nat) -> async (TxReceipt);
                            approve : shared (spender: Principal, value: Nat) -> async (TxReceipt);
                            transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async (TxReceipt);
                        };
                        ignore tocallcanister.transfer(msg.caller, vals);
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
                    expPotions = 0;
                    userLevel = 0;
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
                            expPotions = u.expPotions;
                            userLevel = u.userLevel;
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
                    expPotions = 0;
                    userLevel = 0;
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
        var temp : [var (Principal, Text, Nat, Nat, Nat, Nat, Nat, [Nat], [Nat])] = Array.init<(Principal, Text, Nat, Nat, Nat, Nat, Nat, [Nat], [Nat])>(size, (owner, "", 0, 0, 0,0,0, [], []));
        size := 0;
        for ((k, v) in inventories.entries()) {
            let element : (Principal, Text, Nat, Nat, Nat, Nat, Nat, [Nat], [Nat]) = (k, v.name, v.nbOfChest, v.laserPotions, v.angelPotions, v.expPotions, v.userLevel, v.laserBirds, v.angelBirds);
            temp[size] := element;
            size += 1;
        };
        inventoriesEntries := Array.freeze(temp);
    };

    system func postupgrade() {
        for ((a,b,c,d,e,f,g,h,i) in inventoriesEntries.vals()) {
            let allowed_temp : Inventory = {
                name = b;
                nbOfChest = c;
                laserPotions = d;
                angelPotions = e;
                expPotions = f;
                userLevel = g;
                laserBirds = h;
                angelBirds = i;
            };
            inventories.put(a, allowed_temp);
        };
        inventoriesEntries := [];
    };
} 

// rrkah-fqaaa-aaaaa-aaaaq-cai
