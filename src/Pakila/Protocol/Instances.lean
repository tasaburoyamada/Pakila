import Lean.Data.Json
import Pakila.Protocol.Types

namespace Pakila.Protocol

instance : Repr GovernanceAction where
  reprPrec a _ := match a with
    | .AuditIntegrity => "AuditIntegrity"
    | .SelfHeal       => "SelfHeal"
    | .CheckEngine    => "CheckEngine"

instance : Lean.ToJson GovernanceAction where
  toJson a := Lean.Json.str (match a with
    | .AuditIntegrity => "AuditIntegrity"
    | .SelfHeal       => "SelfHeal"
    | .CheckEngine    => "CheckEngine")

instance : Lean.FromJson GovernanceAction where
  fromJson? j := match j.getStr? with
    | .ok "AuditIntegrity" => .ok .AuditIntegrity
    | .ok "SelfHeal"       => .ok .SelfHeal
    | .ok "CheckEngine"    => .ok .CheckEngine
    | _ => .error "Invalid GovernanceAction"

instance : BEq GovernanceAction where
  beq a b := match a, b with
    | .AuditIntegrity, .AuditIntegrity => true
    | .SelfHeal, .SelfHeal             => true
    | .CheckEngine, .CheckEngine       => true
    | _, _                             => false

instance : Repr MachineAction where
  reprPrec _ _ := "MachineAction"

instance : Lean.ToJson MachineAction where
  toJson a := Lean.Json.obj [("name", Lean.Json.str "action")] -- simplified for demo

instance : Lean.FromJson MachineAction where
  fromJson? _ := .ok MachineAction.Quit

instance : BEq MachineAction where
  beq a b := match a, b with
    | .Quit, .Quit => true
    | _, _ => false

end Pakila.Protocol
