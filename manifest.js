// To test locally:
//
// Set up a local registry on port 5001:
//
//     docker run -d -p 5001:5000 --restart=always --name registry registry:2
//
// Bake images separately for amd64 and arm64 and push them only by their
// SHAs:
//
//     registry=localhost:5001 arch=amd64 pg=17.4 \
//         docker buildx bake \
//         --set '*.output=push-by-digest=true,type=image,push=true' \
//         --set '*.tags=localhost:5001/postgres' \
//         --metadata-file amd64.json
//     registry=localhost:5001 arch=arm64 pg=17.4 \
//         docker buildx bake \
//         --set '*.output=push-by-digest=true,type=image,push=true' \
//         --set '*.tags=localhost:5001/postgres' \
//         --metadata-file arm64.json
//
// Run the script.
//
//     export REGISTRY=localhost:5001
//     node manifest.js *.json
//
// Get a list of all the tags in the registry:
//
//     curl -s localhost:5001/v2/postgres/tags/list | jq

const LATEST_OS="noble"
const LATEST_PG=17

const slurp = require("fs").readFileSync;

if (process.argv.length < 3) {
    console.log(`Usage: ${ process.argv[1] } BUILD_META_FILE [BUILD_META_FILE...]`)
    process.exit(1)
}

// UTC Timestamp in YYYYMMDDhhmm format.
const now = new Date().toISOString().slice(0, 16).replaceAll(/[T:-]/g, "")

let images = {}

for (let i = 2; i < process.argv.length; i++) {
    const build_meta = JSON.parse(slurp(process.argv[i], 'utf8'));

    for (let target in build_meta) {
        // Target defined by target.name in docker-bake.hcl. Example:
        // postgres-17_4-arm64-noble
        const parts = target.split("-")
        const pgv = parts[1].replace("_", "."), arch = parts[2], os = parts[3]
        const [major] = pgv.split(".")
        const key = `${ pgv }-${ os }`
        const digest = build_meta[target]["containerimage.digest"]

        if (!images.hasOwnProperty(key)) {
            // Haven't seen this target, save its digest.
            images[key] = digest
            continue
        }

        const image = `${ process.env.REGISTRY }/postgres`

        // Assemble the image names with their SHAs.
        const shas = `${ image }@${ digest } ${ image }@${ images[key] }`

        // Assemble the tags. They should be the same as those defined in
        // docker-back.hcl's tags() function.
        const tags = [
            `${ image }:${ major }-${ os }`,
            `${ image }:${ pgv }-${ os }`,
            `${ image }:${ pgv }-${ os }-${ now }`,
        ]
        if (os == LATEST_OS) {
            tags.push(
                `${ image }:${ pgv }`,
                `${ image }:${ major }`,
            )
            if (major == LATEST_PG) tags.push(`${ image }:latest`)
        }

        // Create the image manifest.
        exec(`docker buildx imagetools create -t ${ tags.join(" -t ") } ${ shas }`)
        delete images[key]
    }
}

if (!isEmpty(images)) {
    console.error(`Missed some images:\n  ${ Object.keys(images).join("\n  ") }`)
    process.exit(1)
}

function exec(cmd) {
    const exec = require("child_process").exec;
    exec(cmd,  (err, stdout, stderr) => {
        if (stdout != "") console.log(stdout)
        if (err) {
            console.error(err.message)
            process.exit(2)
        }
        if (stderr != "") console.error(stderr)
    })
}

function isEmpty(obj) {
    for (var prop in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, prop)) return false;
    }
    return true
}
