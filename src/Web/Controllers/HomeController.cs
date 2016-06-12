namespace HelloKudu.Web.Controllers {
	using System.Web.Mvc;
	using HelloKudu.Web.Models;

	public class HomeController : Controller {

		public ActionResult Index() {
			ViewBag.GitHash = AssemblyVersionHelper.GitHash;
			return this.View();
		}

	}
}
