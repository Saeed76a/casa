require "rails_helper"
require "sablon"

RSpec.describe CaseCourtReport, type: :model do
  let(:volunteer) { create(:volunteer, :with_cases_and_contacts, :with_assigned_supervisor) }

  describe "when receiving valid case, volunteer, and path_to_template" do
    let(:casa_case_without_contacts) { volunteer.casa_cases.second }
    let(:casa_case_with_contacts) { volunteer.casa_cases.first }
    let(:path_to_template) { Rails.root.join("app", "documents", "templates", "default_report_template.docx").to_s }
    let(:path_to_report) { Rails.root.join("tmp", "test_report.docx").to_s }
    let(:report) do
      CaseCourtReport.new(
        case_id: casa_case_with_contacts.id,
        volunteer_id: volunteer.id,
        path_to_template: path_to_template,
        path_to_report: path_to_report
      )
    end

    describe "With volunteer without supervisor" do
      let(:volunteer) { create(:volunteer, :with_cases_and_contacts) }

      it "has supervisor name placeholder" do
        expect(report.context[:volunteer][:supervisor_name]).to eq("")
      end
    end

    describe "with court date in the future" do
      let!(:far_past_case_contact) { create :case_contact, occurred_at: 5.days.ago, casa_case_id: casa_case_with_contacts.id }

      before do
        casa_case_with_contacts.update!(court_date: 1.day.from_now)
      end

      describe "without past court date" do
        it "has all case contacts ever created for the youth" do
          expect(report.context[:case_contacts].length).to eq(5)
        end
      end

      describe "with past court date" do
        let!(:past_court_date) { create(:past_court_date, date: 2.days.ago, casa_case_id: casa_case_with_contacts.id) }

        it "has all case contacts created since the previous court date" do
          expect(casa_case_with_contacts.past_court_dates.length).to eq(1)
          expect(report.context[:case_contacts].length).to eq(4)
        end
      end
    end

    describe "has valid @context" do
      subject { report.context }

      it { is_expected.not_to be_empty }
      it { is_expected.to be_instance_of Hash }

      it "has the following keys [:created_date, :casa_case, :case_contacts, :volunteer]" do
        expected = %i[created_date casa_case case_contacts volunteer]
        expect(subject.keys).to include(*expected)
      end

      it "must have Case Contacts as type Array" do
        expect(subject[:case_contacts]).to be_instance_of Array
      end

      it "created_date is not nil" do
        expect(subject[:created_date]).to_not be(nil)
      end
    end

    describe "the default generated report" do
      let(:document_data){
        {
          case_number: "1234567890987654321",
          org_address: "596 Unique Avenue Seattle, Washington",
          supervisor_name: "A very unique supervisor name",
          volunteer_name: "An unmistakably unique volunteer name"
        }
      }

      let(:supervisor){ create(:supervisor, display_name: document_data[:supervisor_name]) }
      let(:casa_case){ create(:casa_case, case_number: document_data[:case_number]) }

      # the current date
      # A casa case with
      #  - Date of birth
      #  - is Transitioning
      # Case Contacts with
      #  - contact name
      #  - contact type
      #  - date of contact
      # A case contact type name
      # case mandates with
      #  - order text
      #  - mandate status
      # A volunteer
      #  - date assigned to case
      # hearing date?
      #  report_as_data = report.generate_to_string

      context "when passed all displayable information" do
        before(:each) {
          casa_case_with_contacts.casa_org.update_attribute(:address, document_data[:org_address])
        }

        it "displays all the information" do
          report_as_raw_docx = report.generate_to_string
          report_top_header = get_docx_subfile_contents(report_as_raw_docx, "word/header3.xml")
          report_body = get_docx_subfile_contents(report_as_raw_docx, "word/document.xml")
          

          expect(report_top_header).to include(document_data[:org_address])
        end
      end

      it "contains the current date" do
      end

      it "contains the casa org's address" do
      end

      it "contains the casa case court date" do
      end

      it "contains the casa case date of birth" do
      end

      it "does not display helper text" do
      end

      it "contains all case contact names, types, and dates" do
      end

      it "contains all case court mandate orders and statuses" do
      end

      it "contains the name and date of assignment for the volunteer assigned to the case" do
      end
    end
  end

  describe "when receiving INVALID path_to_template" do
    let(:casa_case_with_contacts) { volunteer.casa_cases.first }
    let(:nonexistent_path) { "app/documents/templates/nonexisitent_report_template.docx" }

    it "will raise Zip::Error when generating report" do
      bad_report = CaseCourtReport.new(
        case_id: casa_case_with_contacts.id,
        volunteer_id: volunteer.id,
        path_to_template: nonexistent_path
      )
      expect { bad_report.generate_to_string }.to raise_error(Zip::Error)
    end
  end
end
