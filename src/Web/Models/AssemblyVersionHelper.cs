namespace HelloKudu.Web.Models {
	using System.Linq;
	using System.Reflection;

	public class AssemblyVersionHelper {
		private static string gitHash = null;

		// FRAGILE: static because they're baked in at compile time and then never change
		// FRAGILE: ASSUME: these values are the same for all dlls in this solution
		static AssemblyVersionHelper() {
			Assembly assembly = Assembly.GetExecutingAssembly();

			// Git hash is in AssemblyInformationalVersion -- build puts it there
			AssemblyInformationalVersionAttribute desc = (
				from a in assembly.GetCustomAttributes(typeof(AssemblyInformationalVersionAttribute), false)
				select a as AssemblyInformationalVersionAttribute
			).First();

			gitHash = desc.InformationalVersion;
		}

		public static string GitHash => gitHash;
	}
}
