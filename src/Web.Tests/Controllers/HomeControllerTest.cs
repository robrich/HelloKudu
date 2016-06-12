namespace HelloKudu.Web.Tests.Controllers {
	using System.Web.Mvc;
	using FluentAssertions;
	using HelloKudu.Web.Controllers;
	using Xunit;

	public class HomeControllerTest {

		[Fact]
		public void Index() {
			// Arrange
			HomeController controller = new HomeController();

			// Act
			ViewResult result = controller.Index() as ViewResult;

			// Assert
			result.Should().NotBeNull();
		}

	}
}
