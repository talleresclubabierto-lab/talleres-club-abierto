import fs from "node:fs";
import path from "node:path";
import solc from "solc";

const contracts = [
  { source: "ClubAbiertoAnchor.sol", name: "ClubAbiertoAnchor" },
  { source: "ClubAbiertoAnchorV2.sol", name: "ClubAbiertoAnchorV2" },
];

fs.mkdirSync(path.resolve("artifacts"), { recursive: true });

for (const item of contracts) {
  const sourcePath = path.resolve("contracts", item.source);
  const source = fs.readFileSync(sourcePath, "utf8");

  const input = {
    language: "Solidity",
    sources: {
      [item.source]: { content: source }
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
    for (const message of output.errors) {
      const printer = message.severity === "error" ? console.error : console.warn;
      printer(message.formattedMessage);
    }
    if (output.errors.some((message) => message.severity === "error")) {
      process.exit(1);
    }
  }

  const artifact = output.contracts[item.source][item.name];

  fs.writeFileSync(
    path.resolve("artifacts", item.name + ".json"),
    JSON.stringify(
      {
        contractName: item.name,
        abi: artifact.abi,
        bytecode: "0x" + artifact.evm.bytecode.object
      },
      null,
      2
    ) + "\n"
  );

  console.log("Contrato compilado:", "artifacts/" + item.name + ".json");
}
