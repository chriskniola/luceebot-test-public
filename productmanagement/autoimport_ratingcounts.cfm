<cfsetting requesttimeout="600">
<cfscript>
if(CGI.request_method IS "POST") {
	try {
		var uploadResults = fileUpload(getTempDirectory(), 'file', 'text/csv', 'MAKEUNIQUE');
		var sanitizedName = lCase(uploadResults.serverfilename).REReplace('[^a-z0-9-_]', '', 'all');
		var s3UniqueFileName = '#createGUID()#.#lCase(uploadResults.serverfileext)#';

		DirectoryCreate(ExpandPath('/partnernet/transfers_inbound/') & 'localuser/powerreviews/', true, true);

		var folderPath = ExpandPath('/partnernet/transfers_inbound/localuser/powerreviews/');
		FileMove('#getTempDirectory()##uploadResults.serverfile#', folderPath & '/' & s3UniqueFileName);
		saveProductReviews("#folderPath#/#s3UniqueFileName#");

	} catch(e) {
		mail subject="ERROR WITH POWER REVIEWS UPLOAD" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(e); }
	}

	private void function saveProductReviews(required string relativeFilePath){
		try {
			var q = csvToQuery(filepath=arguments.relativeFilePath, firstRowIsHeader=true);
			loop query=q {
				insertQuery = new query(datasource=DSN);
				insertQuery.setSql("
						IF(NOT EXISTS (SELECT 1 FROM Reviews.ProductReviews WHERE ReviewID = :ReviewID))
							BEGIN
								INSERT INTO Reviews.ProductReviews (ReviewID, CreatedDate, PageID, Manufacturer, ModelNumber, ReviewRating, ReviewHeadline, ReviewComments, ReviewBottomLine, ReviewLocation, ReviewerType, Observations, SiteStatus, ObservedBy, LastPublicationModifiedDate, IsPWRPublishable, Source, CampaignID, OrderID, ReviewNickName, ReviewEmail, MerchantResponse, VerifiedReviewerFlag, ServiceComments)
									VALUES(:ReviewID, :CreatedDate, :PageID, :Manufacturer, :ModelNumber, :ReviewRating, :ReviewHeadline, :ReviewComments, ISNULL(:ReviewBottomLine,0), :ReviewLocation, :ReviewerType, :Observations, :SiteStatus, :ObservedBy, :LastPublicationModifiedDate, :IsPWRPublishable, :Source, :CampaignID, :OrderID, :ReviewNickName, :ReviewEmail, :MerchantResponse, :VerifiedReviewerFlag, :ServiceComments)
							END
						ELSE
							BEGIN
								UPDATE Reviews.ProductReviews
								SET   CreatedDate = :CreatedDate
									, PageID = :PageID
									, Manufacturer = :Manufacturer
									, ModelNumber = :ModelNumber
									, ReviewRating = :ReviewRating
									, ReviewHeadline = :ReviewHeadline
									, ReviewComments = :ReviewComments
									, ReviewBottomLine= ISNULL(:ReviewBottomLine,0)
									, ReviewLocation = :ReviewLocation
									, ReviewerType = :ReviewerType
									, Observations = :Observations
									, SiteStatus = :SiteStatus
									, ObservedBy = :ObservedBy
									, LastPublicationModifiedDate = :LastPublicationModifiedDate
									, IsPWRPublishable = :IsPWRPublishable
									, Source = :Source
									, CampaignID = :CampaignID
									, OrderID = :OrderID
									, ReviewNickName = :ReviewNickName
									, ReviewEmail = :ReviewEmail
									, MerchantResponse = :MerchantResponse
									, VerifiedReviewerFlag = :VerifiedReviewerFlag
									, ServiceComments = :ServiceComments
								WHERE ReviewID = :ReviewID
							END
					");

				insertQuery.addParam(name='ReviewID', sqltype='INT', value=q['Review ID']);
				insertQuery.addParam(name='CreatedDate', sqltype='DATE', value=q['Created Date']);
				insertQuery.addParam(name='PageID', sqltype='VARCHAR', value=q['Page ID']);
				insertQuery.addParam(name='Manufacturer', sqltype='VARCHAR', value=q['Brand Name'], null=isEmpty(q['Brand Name']));
				insertQuery.addParam(name='ModelNumber', sqltype='VARCHAR', value=q['Manufacturer Model Number'], null=isEmpty(q['Manufacturer Model Number']));
				insertQuery.addParam(name='ReviewRating', sqltype='INT', value=q['Review Rating']);
				insertQuery.addParam(name='ReviewHeadline', sqltype='VARCHAR', value=q['Review Headline'], null=isEmpty(q['Review Headline']));
				insertQuery.addParam(name='ReviewComments', sqltype='LONGVARCHAR', value=q['Review Comments'], null=isEmpty(q['Review Comments']));
				insertQuery.addParam(name='ReviewBottomLine', sqltype='BIT', value=q['Review Bottomline'], null=isEmpty(q['Review Bottomline']));
				insertQuery.addParam(name='ReviewLocation', sqltype='VARCHAR', value=q['Review Location'], null=isEmpty(q['Review Location']));
				insertQuery.addParam(name='ReviewerType', sqltype='VARCHAR', value=q['Reviewer Type'], null=isEmpty(q['Reviewer Type']));
				insertQuery.addParam(name='Observations', sqltype='VARCHAR', value=q['Observations'], null=isEmpty(q['Observations']));
				insertQuery.addParam(name='SiteStatus', sqltype='VARCHAR', value=q['Site Status'], null=isEmpty(q['Site Status']));
				insertQuery.addParam(name='ObservedBy', sqltype='VARCHAR', value=q['Observed By'], null=isEmpty(q['Observed By']));
				insertQuery.addParam(name='LastPublicationModifiedDate', sqltype='TIMESTAMP', value=q['Last Publication Modified Date'], null=isEmpty(q['Last Publication Modified Date']));
				insertQuery.addParam(name='IsPWRPublishable', sqltype='VARCHAR', value=q['Is PWR Publishable'], null=isEmpty(q['Is PWR Publishable']));
				insertQuery.addParam(name='Source', sqltype='VARCHAR', value=q['Source'], null=isEmpty(q['Source']));
				insertQuery.addParam(name='CampaignID', sqltype='VARCHAR', value=q['Campaign ID'], null=isEmpty(q['Campaign ID']));
				insertQuery.addParam(name='OrderID', sqltype='VARCHAR', value=q['Order ID'], null=isEmpty(q['Order ID']));
				insertQuery.addParam(name='ReviewNickName', sqltype='VARCHAR', value=q['Review Nickname'], null=isEmpty(q['Review Nickname']));
				insertQuery.addParam(name='ReviewEmail', sqltype='VARCHAR', value=q['Review Email'], null=isEmpty(q['Review Email']));
				insertQuery.addParam(name='MerchantResponse', sqltype='LONGVARCHAR', value=q['Merchant Response'], null=isEmpty(q['Merchant Response']));
				insertQuery.addParam(name='VerifiedReviewerFlag', sqltype='BIT', value=q['Verified Reviewer Flag'], null=isEmpty(q['Verified Reviewer Flag']));
				insertQuery.addParam(name='ServiceComments', sqltype='LONGVARCHAR', value=q['Service Comments'], null=isEmpty(q['Service Comments']));

				insertQuery.execute().getResult();
			}
			mail subject="POWER REVIEWS IMPORTED SUCCESSFULLY" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump('Number of reviews updated/inserted ' & q.recordCount); }
		} catch (e) {
			mail subject="Error Importing Product Ratings" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(e); }
		}
	}
}
</cfscript>
