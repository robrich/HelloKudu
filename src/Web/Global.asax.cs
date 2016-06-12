namespace HelloKudu.Web {
	using System.Web;
	using System.Web.Mvc;
	using System.Web.Routing;
	using HelloKudu.Web.App_Start;

	public class MvcApplication : HttpApplication {
		protected void Application_Start() {
			AreaRegistration.RegisterAllAreas();
			FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
			RouteConfig.RegisterRoutes(RouteTable.Routes);
		}
	}
}
