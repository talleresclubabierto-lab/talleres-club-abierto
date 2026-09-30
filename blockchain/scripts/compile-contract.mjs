import fs from "node:fs";
import path from "node:path";
import solc from "solc";

const sourcePath = path.resolve("contracts/ClubAbiertoAnchor.sol");
const source = fs.readFileSync(sourcePath, "utf8");

const input = {
  language: "Solidity",
  sources: {
    "ClubAbiertoAnchor.sol": { content: source }
  },
  settings: {
    optimizer: { enabled: true, runs: 200 },
    outputSelection: {
      "*": {
        "*": ["abi", "evm.bytecode.object"]
      }
    }
  }
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  for (const item of output.errors) {
    const printer = item.severity === "error" ? console.error : console.warn;
    printer(item.formattedMessage);
  }
  if (output.errors.some((item) => item.severity === "error")) {
    process.exit(1);
  }
}

const artifact = output.contracts["ClubAbiertoAnchor.sol"]["ClubAbiertoAnchor"];

fs.mkdirSync(path.resolve("artifacts"), { recursive: true });
fs.writeFileSync(
  path.resolve("artifacts/ClubAbiertoAnchor.json"),
  JSON.stringify(
    {
      contractName: "ClubAbiertoAnchor",
      abi: artifact.abi,
      bytecode: "0x" + artifact.evm.bytecode.object
    },
    null,
    2
  ) + "\n"
);

console.log("Contrato compilado: artifacts/ClubAbiertoAnchor.json");
