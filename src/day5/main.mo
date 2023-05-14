import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Buffer "mo:base/Buffer";

import Type "Types";
import Ic "Ic";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(0, Principal.equal, Principal.hash);

  private func isRegistered(p : Principal) : Bool {
    var xProfile : ?StudentProfile = studentProfileStore.get(p);

    switch (xProfile) {
      case null { 
        return false;
      };

      case (?profile) {
        return true
      };
    }
  };

  // STEP 1 - BEGIN

  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In"
    };

    if (isRegistered(caller)) {
      return #err ("You are already registered (" # Principal.toText(caller) # ") ")
    };

    studentProfileStore.put(caller, profile);
    return #ok ();
  };

  public shared query ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    var xProfile : ?StudentProfile = studentProfileStore.get(p);

    switch (xProfile) {
      case null { 
        return #err ("There is no profile registered with the received account");
      };

      case (?profile) {
        return #ok profile
      };
    }
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In"
    };
    
    if (not isRegistered(caller)) {
      return #err ("You are not registered");
    };

    ignore studentProfileStore.replace(caller, profile);

    return #ok ();
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In"
    };
    
    if (not isRegistered(caller)) {
      return #err ("You are not registered");
    };

    studentProfileStore.delete(caller);

    return #ok ();
  };

  // STEP 2 - BEGIN
  public shared func test(canisterId: Principal): async Type.TestResult{
    let calculator = actor(Principal.toText(canisterId)) : actor {
      add: (Int) -> async (Int);
      reset: () -> async (Int);
      sub: (Int) -> async (Int);
    };
    //Testing reset
    var ans: Int = 0;

    try{
      ans := await calculator.reset();
    }catch (e){
      return #err(#UnexpectedError("The function reset is not defined"));
    };

    try{
      ans := await calculator.add(1);
    }catch (e){
      return #err(#UnexpectedError("The function add is not defined"));
    };

    try{
      ans := await calculator.sub(1);
    }catch (e){
      return #err(#UnexpectedError("The function sub is not defined"));
    };

    ans := await calculator.reset();
    ans := await calculator.add(1);

    if(not (ans == 1)){
      return #err(#UnexpectedValue("The function add is not well implemented"));
    };

    ans := await calculator.reset();
    ans := await calculator.sub(1);

    if(not (ans == -1)){
      return #err(#UnexpectedValue("The function sub is not well implemented"));
    };
    
    ans := await calculator.reset();
    if(not (ans == 0)){
      return #err(#UnexpectedValue("The function reset is not well implemented"));
    };

    return #ok();
  };


  // STEP 3 - BEGIN
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    try {
      let controllers = await Ic.getCanisterControllers(canisterId);

      var isOwner : ?Principal = Array.find<Principal>(controllers, func prin = prin == p);
      
      if (isOwner != null) {
        return true;
      };

      return false;
    } catch (e) {
      return false;
    }
  };

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    try {
      let isApproved = await test(canisterId); 

      if (isApproved != #ok) {
        return #err("The current work has no passed the tests");
      };

      let isOwner = await verifyOwnership(canisterId, p); 

      if (not isOwner) {
        return #err ("The received work owner does not match with the received principal");
      };

      var xProfile : ?StudentProfile = studentProfileStore.get(p);

      switch (xProfile) {
        case null { 
          return #err("The received principal does not belongs to a registered student");
        };

        case (?profile) {
          var updatedStudent = {
            name = profile.name;
            graduate = true;
            team = profile.team;
          };

          ignore studentProfileStore.replace(p, updatedStudent);
          return #ok ();      
        }
      };
    } catch(e) {
      return #err("Cannot verify the project");
    }
  };
  
};