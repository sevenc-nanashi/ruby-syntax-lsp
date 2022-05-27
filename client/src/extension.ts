import { spawn } from "child_process"
import { window, workspace } from "vscode"
import { commands, ExtensionContext } from "vscode"

import {
  LanguageClient,
  LanguageClientOptions,
} from "vscode-languageclient/node"

let client: LanguageClient

export function activate(context: ExtensionContext) {
  const serverOptions = async () => {
    const serverPath: string =
      workspace.getConfiguration("ruby-syntax-lsp").get("lspPath") ||
      "ruby_syntax_lsp"
    const serverArgs: string =
      workspace.getConfiguration("ruby-syntax-lsp").get("lspArgs") || ""
    const processCommand = serverPath + " " + serverArgs
    console.log("Starting server: " + processCommand)
    if (process.platform === "win32") {
      return spawn(
        process.env.SYSTEMROOT + "\\System32\\cmd.exe",
        ["/c", processCommand],
        { cwd: context.extensionPath }
      )
    } else {
      return spawn("/bin/sh", ["-c", processCommand], {
        cwd: context.extensionPath,
      })
    }
  }

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "ruby" }],
  }

  client = new LanguageClient(
    "ruby-syntax-lsp",
    "Ruby Syntax LSP",
    serverOptions,
    clientOptions
  )

  client.start()

  context.subscriptions.push(
    commands.registerCommand("ruby-syntax-lsp.restartServer", () => {
      window.showInformationMessage("Restarting Ruby Syntax LSP server...")
      client.stop()
      client.start()
    })
  )
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined
  }
  return client.stop()
}
