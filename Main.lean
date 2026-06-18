import Pakila.CLI.App

def main (args : List String) : IO Unit := do
  -- 本物の CLI アプリケーションの起動ロジックに完全委譲
  Pakila.CLI.App.run args