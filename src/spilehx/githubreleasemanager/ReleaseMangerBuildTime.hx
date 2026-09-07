package spilehx.githubreleasemanager;

#if macro
class ReleaseMangerBuildTime {
	private static final DEFAULT_RELEASE_PATH:String = "bin";

	private static final RELEASE_INFO_FILE_NAME:String = "release_info.json";

	public static macro function setup():Void {
		printInfo(" ----- Running Release Manager Build Time Setup ----- ");
		Sys.println("");
		createReleaseInfoFile();
		Sys.println("");
		printInfo(" -------------------- ");
		Sys.println("");
	}

	public static macro function release():Void {
		printInfo(" ----- Running Release Manager Build Time Release ----- ");
		Sys.println("");
		var releaseInfo = haxe.Json.parse(getReleaseInfoFileContent());
		copyBuildToRelease(releaseInfo);
		Sys.println("");
		printInfo(" --------- DONE ----------- ");
	}

	private static function copyBuildToRelease(releaseInfo:Dynamic):Void {
		var buildPath:String = releaseInfo.buildPath + "/" + releaseInfo.buildFileName;
		var releasePath:String = releaseInfo.releasePath;

		if (sys.FileSystem.exists(buildPath)) {
			printInfo("Found Build: " + buildPath);
			printInfo("Creating release here: " + releasePath);

			// copy build file to release directory
			Sys.command("mkdir", ["-p", releaseInfo.releaseDir]);
			Sys.command("mv", [buildPath, releasePath]);
		} else {
			printErr("Build file not found: " + buildPath);
			haxe.macro.Context.fatalError("FAILED", haxe.macro.Context.currentPos());
		}
	}

	private static function getReleaseInfoFileContent():String {
		var releaseInfoFilePath:String = Sys.getCwd() + "/" + RELEASE_INFO_FILE_NAME;
		if (sys.FileSystem.exists(releaseInfoFilePath)) {
			return sys.io.File.getContent(releaseInfoFilePath);
		} else {
			printErr("Release info file not found: " + releaseInfoFilePath);
			return "{}";
		}
	}

	private static function getBuildTimeStamp():String {
		var timestamp:Int = Math.floor(Date.now().getTime() / 1000);
		return Std.string(timestamp);
	}

	private static function createReleaseInfoFile() {
		var releaseInfo = {
			releaseDir: getReleaseDirPath(),
			architecture: getHostArchitecture(),
			buildFileName: getBuildFileName(),
			buildPath: haxe.macro.Compiler.getOutput(),
			releaseFileName: getReleaseFileName(),
			releasePath: getReleasePath(),
			buildTimeStamp: getBuildTimeStamp()
		};

		var fieldNames = Reflect.fields(releaseInfo);
		var releaseInfoStr = "{\n";
		for (fieldName in fieldNames) {
			var fieldValue = Reflect.field(releaseInfo, fieldName);
			releaseInfoStr += '  "' + fieldName + '": "' + fieldValue + '",\n';
		}
		releaseInfoStr += "}\n";

		printInfo("Release Info: " + releaseInfoStr);

		// writeReleaseInfoToFile(releaseInfo, haxe.macro.Compiler.getOutput());
		writeReleaseInfoToFile(releaseInfo);
	}

	private static function writeReleaseInfoToFile(releaseInfo:Dynamic):Void {
		var filePath:String = Sys.getCwd() + "/" + RELEASE_INFO_FILE_NAME;
		var releaseInfoStr:String = haxe.Json.stringify(releaseInfo, null, "    ");
		sys.io.File.saveContent(filePath, releaseInfoStr);
	}

	private static function getBuildPath():String {
		var outputDir:String = haxe.macro.Compiler.getOutput();
		var outputFilePath:String = outputDir + "/" + getBuildFileName();
		return outputFilePath;
	}

	private static function getBuildFileName():String {
		var config:haxe.macro.Compiler.CompilerConfiguration = haxe.macro.Compiler.getConfiguration();
		var mainClassName:String = config.mainClass.name;
		return mainClassName;
	}

	private static function getReleaseFileName():String {
		var hostArchitecture:String = getHostArchitecture();
		var releaseFileName:String = getBuildFileName() + "." + hostArchitecture;
		return releaseFileName;
	}

	private static function getReleaseDirPath():String {
		var releaseDir = haxe.macro.Context.definedValue("RELEASE_DIR");
		if (releaseDir == null) {
			releaseDir = DEFAULT_RELEASE_PATH;
		}
		return releaseDir;
	}

	private static function getReleasePath():String {
		return getReleaseDirPath() + "/" + getReleaseFileName();
	}

	private static function getHostArchitecture():String {
		var sysName:String = Sys.systemName().toLowerCase();
		var architecture:String = "";

		if (sysName == "linux") {
			var process = new sys.io.Process("uname", ["-m"]);
			var result = process.stdout.readAll().toString();
			result = StringTools.trim(result);

			process.close();
			architecture = result.toLowerCase();
		} else {
			printErr("Unsupported system: " + sysName);
			haxe.macro.Context.fatalError("FAILED", haxe.macro.Context.currentPos());
		}

		var hostArchitecture:String = sysName + "_" + architecture;

		addDefine("BUILD_ARCHITECTURE", hostArchitecture);

		return hostArchitecture;
	}

	private static function addDefine(key:String, value:Dynamic) {
		haxe.macro.Compiler.define(key, value);
	}

	private static function printInfo(message:String):Void {
		printMsg(message, 32);
	}

	private static function printErr(message:String):Void {
		printMsg(message, 31);
	}

	private static function printLog(message:String):Void {
		printMsg(message);
	}

	private static function printMsg(message:String, col:Int = 0):Void {
		if (col > 0) {
			Sys.println("\033[1;" + col + "m" + message + " \033[0m");
		} else {
			Sys.println(message);
		}
	}
}
#end
