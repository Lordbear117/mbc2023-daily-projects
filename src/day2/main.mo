import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

import Type "Types";

actor class Homework() {

  type Homework = Type.Homework;
  type Pattern = Text.Pattern;

  let homeworkDiary = Buffer.Buffer<Homework>(2);
  let homeworkDiaryPending = Buffer.Buffer<Homework>(2);
  let homeworkSearch = Buffer.Buffer<Homework>(2);

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return homeworkDiary.size() -1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id <= homeworkDiary.size()) {
      return #ok(homeworkDiary.get(id));
    } else {
      return #err("Homework not found");
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (homeworkDiary.getOpt(id) == null) {
      return #err("Homework not found");
    } else {
      let updateHomework : Homework = {
        title : Text = homework.title;
        description : Text = homework.description;
        //dueDate : Time = homework.dueDate;
        dueDate = homework.dueDate;
        completed : Bool = homework.completed;
      };
      homeworkDiary.put(id, updateHomework);
      return #ok();
    };
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (homeworkDiary.getOpt(id) == null) {
      return #err("Homework not found");
    } else {
      let homework = homeworkDiary.get(id);
      let updateHomework : Homework = {
        title : Text = homework.title;
        description : Text = homework.description;
        //dueDate : Time = homework.dueDate;
        dueDate = homeworkDiary.get(id).dueDate;
        completed : Bool = true;
      };
      homeworkDiary.put(id, updateHomework);
      return #ok();
    };
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (id <= homeworkDiary.size()) {
      let removed = homeworkDiary.remove(id);
      return #ok();
    } else {
      return #err("Homework not found");
    };
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray<Homework>(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    for (element in homeworkDiary.vals()) {
      if (element.completed != true) {
        homeworkDiaryPending.add(element);
      };
    };
    return Buffer.toArray<Homework>(homeworkDiaryPending);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
   
    //Create a pattern from the search term
    let p : Pattern = #text(searchTerm);

    if (searchTerm == "") {
      return Buffer.toArray<Homework>(homeworkDiary);
    } else {
      for (element in homeworkDiary.vals()) {
        //Use pattern matching to search for the search term in the title
        if (Text.contains(element.title, p)) {
          homeworkSearch.add(element);
        };
      };
     
      return Buffer.toArray<Homework>(homeworkSearch);

    };
  };
};
