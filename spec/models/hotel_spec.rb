# frozen_string_literal: true

RSpec.describe Hotel do
  before do
    sql = <<~SQL
    SELECT setval('hotels_id_seq'::regclass, 5000, 't');

    INSERT INTO hotels (id, name, hotel_time, time_in_japan, opening_day) VALUES
      (100, 'Wonky', '2023-04-25 13:22:54.833 -0700', '2023-07-23 21:22:55.021 +9:00', '1998-03-18');

    UPDATE hotels SET hotel_time='2023-10-12 14:18:29.422', time_in_japan='2023-10-13T17:16:15.021+0200' WHERE id=100;
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end

  let(:hotel) { Hotel.find(100) }
  let(:ordered_trails) { hotel.iron_trails.order(id: :asc) }
  let(:app_time_zone) { 'America/Santiago' }

  it 'is sane' do
    expect(ordered_trails).to have_attributes(count: 2)
  end

  describe 'timestamp WITHOUT time zone column' do
    before { hotel }

    it 'deserializes correctly' do
      original_hotel = in_time_zone(app_time_zone) do
        ordered_trails.first.reify
      end

      utc_zone = ActiveSupport::TimeZone['UTC'] # +00:00
      jp_zone = ActiveSupport::TimeZone['Tokyo'] # +09:00

      original_time_utc = utc_zone.local(2023, 4, 25, 13, 22, 54, 833000)
      current_time_utc = utc_zone.local(2023, 10, 12, 14, 18, 29, 422000)

      expect(original_hotel.hotel_time).to eq(original_time_utc)
      expect(hotel.hotel_time).to eq(current_time_utc)
    end
  end

  describe 'timestamp WITH time zone column' do
    it 'deserializes correctly' do
      original_hotel = in_time_zone(app_time_zone) do
        ordered_trails.first.reify
      end

      jp_zone = ActiveSupport::TimeZone['Tokyo'] # +09:00
      de_zone = ActiveSupport::TimeZone['Europe/Berlin'] # +02:00

      original_japan_time = jp_zone.local(2023, 7, 23, 21, 22, 55, 21000)
      current_japan_time = de_zone.local(2023, 10, 13, 17, 16, 15, 21000)

      expect(original_hotel.time_in_japan).to eq(original_japan_time)
      expect(hotel.time_in_japan).to eq(current_japan_time)
    end
  end

  context 'when the hotel has an owner' do
    let(:hotel_owner) { Person.create!(first_name: 'Ada', last_name: 'Lacelove', owns_the_hotel: 100) }

    before do
      hotel_owner

      hotel.reload
    end

    context 'when there was a owner_person in the old times' do
      subject(:reify_it) { hotel.iron_trails.inserts.first.reify }

      before do
        trail = hotel.iron_trails.inserts.first
        trail.rec_new['owner_person'] = nil
        trail.save!

        hotel.reload
      end

      it 'does not reify a non-attribute' do
        expect(hotel.owner_person).to eq(hotel_owner)

        reify_it

        expect(Person.find_by(id: hotel_owner.id)).to eq(hotel_owner)
      end

      it 'reifies owner_person as a ghost attribute' do
        reify_it

        expect(reify_it.irontrail_reified_ghost_attributes).to match({
          'owner_person' => nil
        })
      end
    end
  end

  private

  def in_time_zone(new_tz)
    original_tz = Time.zone
    begin
      Time.zone = new_tz

      yield
    ensure
      Time.zone = original_tz
    end
  end
end
